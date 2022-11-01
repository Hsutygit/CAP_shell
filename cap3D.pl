#!/usr/bin/env perl
#
# A user-friendly PERL interface to the CAP3D source inversion code cap3D
#
# written by Lupei Zhu, 3/6/1998, Caltech
# 
# revision history
#	6/18/2001	add usage and documentation.
#	11/05/2012	add isotropic and CLVD search (-J).
#	1/13/2013	add option to output potency tensor parameters.
#	04/15/2014	add option to use 3D Green's function (-Y).
#	05/05/2015	no need of initial magnitude input.
#

# these are the only things one need to change based on the site installation
$home = $ENV{HOME};			# my home directory
#require "$home/Src/cap/cap_plt.pl";	# include plot script
require "/mnt/e/EQs/2016Menyuan/cap/M3.9/cap_plt.pl";

#================defaults======================================
$cmd = "cap3D";
#$green = "$home/data/models/Glib";	#green's function location
$green = "/mnt/e/EQs/2016Menyuan/cap/M3.9";
$ngf = 3;				#number of fundamental sources of 1D FK Green's functions for DC
$eloc = ".";
$repeat = 0;
$bootstrap = 0;
$fm_thr = 0.01;
$appdx='';
$disp=0;
$mltp=0;
$weight="weight.dat";

# plotting
$plot = 0;
$amplify = 0.5;
$sec_per_inch = 40;
$keep = 0;

$dura = 1.;	# source duration in sec
$rise = 0.5;	# rise time in portion to duration

# filters and window lengths
($f1_pnl, $f2_pnl, $f1_sw, $f2_sw, $m1, $m2) = (0.02,0.2,0.02,0.1,35,70);

# max. shifts
$max_shft1=1;		# max. shift for Pnl
$max_shft2=5;		# max. shift for surface wave
$tie = 0.5;		# tie between SV and SH

# weights between different portions
$weight_of_pnl=2;		# weight for pnl portions
$power_of_body=1;		# distance scaling power for pnl waves
$power_of_surf=0.5;

# apparent velocities
#($vp, $love, $rayleigh) = (7.8, 3.5, 3.1);
($vp, $love, $rayleigh) = (-1, -1, -1);

# default grid-search ranges
($deg) = 10;
$str1 = 0; $str2 = 360;
$dip1 = 0; $dip2 = 90;
$rak1 = -90; $rak2 = 90;
$iso = $diso = $clvd = $dclvd = 0.;
$vpvs = 0;
$mu = 0;

# number of freedom per sample for estimating uncertainty
$nof = 0.01;
$dt = 0.1;

# rms thresholds for discarding bad traces
@thrshd = (10., 10., 10., 10., 10.);

# command line input, [] means optional, see () for default value
$usage = 
" ===== CAP seismic source tensor inversion using seismic waveforms ====
	Ref: Zhu and Helmberger, 1996, BSSA 86, 1645-1641.
	     Zhu and Ben-Zion, 2013, GJI, submitted.

  Data preparation:
     Put all three-component waveforms station.[r,t,z] of the event in
  a single directory named with the event ID. The data should be velocity
  in cm/s or displacement in cm in the SAC format, with the reference
  time set at the origin time and epicentral distance and azimuth
  set in the SAC header. There should be another file called $weight
  in the same directory, in the following format:
	StationName dist w1 w2 w3 w4 w5 tp ts
  where dist specifies the names of Green functions (dist.grn.?) to be used.
  w1 to w5 are the weights for 5 segments of waveforms: PnlZ, PnlR, Z, R, T.
  tp is first P arrival time if it's set to a positive value. ts is the initial
  time shift for the surface waves, positive means that the data is delayed w.r.t. the model.
  If w2 is set to -1, it indicates that the station is at teleseimic distances and only
  the P (PnlZ) and SH (T) are used. In this case, w3 is the t*p, w4 is t*s, and
  ts is the S arrival time when it is positive.

  The Greens function library:
     1D Green functions are computed using FK, named as
  model/model_edepth/dist.grn.[0-8,a-c]. They are in SAC format with
  two time marks set: t1 for the first P arrival and t2 for the first S arrival.
  If first-motion data are to be used in the inversion, the Greens functions
  need to have user1 and user2 set as the P and S take-off angles (in degrees from down).
     3D Green functions are computed using FD, named as
  model/model_edepth/eloc/StationName.mt.[a-r].
  They are mxx.[U,R,T], 2mxy.[U,R,T], 2mxz.[U,R,T], myy.[U,R,T], 2myz.[U,R,T],
  and mzz.[U,R,T] (x=N, y=E, z=D).

  Time window determination:
     The inversion breaks the whole record into two windows, the Pnl window
  and the surface wave window. These windows are determined in following way:
    1) If the SAC head has time mark t1, t2 set, the code will use them for
       the Pnl window. The same is true for the surface wave window (using t3 and t4).
    Otherwise,
    2) If positive apparent velocities are given to the code (see -V below), it will use
       them to calculate the time windows:
	  t1 = dist/vp - 0.3*m1, t2 = ts + 0.2*m1
	  t3 = dist/vLove - 0.3*m2, t4 = dist/vRayleigh + 0.7*m2
    Otherwise,
    3) Using the tp, ts in the Green function header
 	  t1 = tp - 0.2*m1,  t2 = t1+m1
	  t3 = ts - 0.3*m2,  t4 = t3+m2
    Here m1, m2 are the maximum lengths for the Pnl and surface waves windows
    (see the -T options below).

  Usage: cap3D.pl -Mmodel_depth [-B] [-Cf1_pnl/f2_pnl/f1_sw/f2_sw] [-Dw1[/p1[/p2]]] [-Fthr] [-Ggreen] [-Hdt] [-Idd] [-J[iso[/diso[/clvd[/dclvd]]]]] [-Kvpvs[/mu]] [-Ltau[/rise]] [-Nn] [-O] [-PYscale[/Xscale[/k]]] [-Qnof] [-Rstrike1/strike2/dip1/dip2/rake1/rake2] [-Ss1/s2[/tie]] [-Tm1/m2] [-Udirectivity] [-Vvp/vl/vr] [-Wi] [-Xn] [-Y[eloc]] [-Zstring] event_dirs
    -B  output misfit errors of all solutions for bootstrapping late ($bootstrap).
    -C  filters for Pnl and surface waves, specified by the corner
	frequencies of the band-pass filter. ($f1_pnl/$f2_pnl/$f1_sw/$f2_sw).
    -D	weight for Pnl (w1) and distance scaling powers for Pnl (p1) and surface
   	waves (p2). If p1 or p2 is negative, all traces will be normalized. ($weight_of_pnl/$power_of_body/$power_of_surf).
    -F	include first-motion data in the search. thr is the threshold ($fm_thr).
    	The first motion data are specified in $weight. The polarities
	can be specified using +-1 for P, +-2 for SV, and +-3 for SH after
	the station name, e.g. LHSA/+1/-3 means that P is up and SH is CCW.
	The Green functions need to have take-off angles stored in the SAC header.
    -G  Green's function library location ($green).
    -H  dt ($dt).
    -I  search interval in deg. for strike/dip/rake ($deg).
    -J  include isotropic and CLVD search using initial values iso/clvd and steps diso/dclvd (0/0/0/0).
    -K	use the vpvs ratio and mu at the source to compute potency tensor parameters ISO and P0. (0/0, off).
    -L  source duration in sec and rise time portion or a SAC STF file name ($dura/$rise).
    -M	specify the model name and source depth in km.
    -N  repeat the inversion n times and discard bad traces ($repeat).
    -O  output CAP input (off).
    -P	generate waveform-fit plot with plotting scale.
    	Yscale: amplitude in inch for the first trace of the page ($amplify).
	Xscale: seconds per inch. ($sec_per_inch).
	append k if one wants to keep those waveforms.
    -Q  number of freedom per sample ($nof)
    -R	grid-search range for strike/dip/rake (0/360/0/90/-90/90).
    -S	max. time shifts in sec for Pnl and surface waves ($max_shft1/$max_shift2) and
	tie between SH shift and SV shift:
	 tie=0 		shift SV and SH independently,
	 tie=0.5 	force the same shift for SH and SV ($tie).
    -T	max. time window lengths for Pnl and surface waves ($m1/$m2).
    -U  directivity, specify rupture direction on the fault plane (off).
    -V	apparent velocities for Pnl, Love, and Rayleigh waves (off).
    -W  use displacement for inversion; 1=> data in velocity; 2=> data in disp ($disp use velocity).
    -X  output other local minimums whose misfit-min<n*sigma ($mltp).
    -Y  use 3D GF and specify the eloc ($eloc). See the 3D GF specification above.
    -Z  specify a different weight file name ($weight).

Examples:
> cap3D.pl -H0.2 -P0.3 -S2/5/0 -T35/70 -F -D2/1/0.5 -C0.05/0.3/0.02/0.1 -W1 -X10 -Mcus_15 20080418093700
  which finds the best focal mechanism and moment magnitude of tbe 2008/4/18 Southern Illinois earthquake
  20080418093700 using the central US crustal velocity model cus with the earthquake at a depth of 15 km.
  Here we assume that the Greens functions have already been computed and saved in $green/cus/cus_15/.
  The inversion results are saved in cus_15.out with the first line
Event 20080418093700 Model cus_15 FM 115 90  -2 Mw 5.19 rms 1.341e-02   110 ERR   1   3   4
  saying that the fault plane solution is strike 115, dip 90, and rake -2 degrees, with the
  axial lengths of the 1-sigma error ellipsoid of 1, 3, and 4 degrees.
  The rest of the files shows rms, cross-correlation coef., and time shift of individual waveforms.
  The waveform fits are plotted in file cus_15.ps in the event directory.

  To find the best focal depth, repeat the inversion for different focal depths:
> for h in 05 10 15 20 25 30; do ./cap3D.pl -H0.2 -P0.3 -S2/5/0 -T35/70 -F -D2/1/0.5 -C0.05/0.3/0.02/0.1 -W1 -X10 -Mcus_\$h 20080418093700; done
  and store all the results in a temporary file:
> grep -h Event 20080418093700/cus_*.out > junk.out
  and then run
> ./depth.pl junk.out 20080418093700 > junk.ps
  The output from the above command
Event 20080418093700 Model cus_15 FM 115 90  -2 Mw 5.19 rms 1.341e-02   110 ERR   1   3   4 H  14.8 0.6
  shows that the best focal depth is 14.8 +/- 0.6 km.

  To include isotropic and CLVD in the inversion, use the -J option to specify the starting iso0, clvd0, and search steps. It requires
  that the Green's function library includes the explosion source components (.a, .b, .c).


";

@ARGV > 1 || die $usage;

$ncom = 5;	# 5 segemnts to plot

#input options
foreach (grep(/^-/,@ARGV)) {
   $opt = substr($_,1,1);
   @value = split(/\//,substr($_,2));
   if ($opt eq "B") {
     $bootstrap = 1;
   } elsif ($opt eq "C") {
     ($f1_pnl, $f2_pnl, $f1_sw, $f2_sw) = @value;
   } elsif ($opt eq "D") {
     $weight_of_pnl  = $value[0] if $value[0];
     $power_of_body  = $value[1] if $value[1];
     $power_of_surf  = $value[2] if $value[2];
   } elsif ($opt eq "F") {
     $fm_thr = $value[0] if $#value >= 0;
   } elsif ($opt eq "G") {
     $green = substr($_,2);
   } elsif ($opt eq "H") {
     $dt = $value[0];
   } elsif ($opt eq "I") {
     $deg = $value[0];
   } elsif ($opt eq "J") {
     $iso   = $value[0] if $value[0];
     $diso  = $value[1] if $value[1];
     $clvd  = $value[2] if $value[2];
     $dclvd = $value[3] if $value[3];
   } elsif ($opt eq "K") {
     $vpvs = $value[0] if $value[0];
     $mu   = $value[1] if $value[1];
   } elsif ($opt eq "L") {
     $dura = $value[0];
     $rise = $value[1] if $value[1];
   } elsif ($opt eq "M") {
     ($md_dep) = @value;
   } elsif ($opt eq "N") {
     $repeat = $value[0];
   } elsif ($opt eq "O") {
     $cmd = "cat";
   } elsif ($opt eq "P") {
     $plot = 1;
     $amplify = $value[0] if $#value >= 0;
     $sec_per_inch = $value[1] if $#value > 0;
     $keep = 1 if $#value > 1;
   } elsif ($opt eq "Q") {
     $nof = $value[0];
   } elsif ($opt eq "R") {
     ($str1,$str2,$dip1,$dip2,$rak1,$rak2) = @value;
   } elsif ($opt eq "S") {
     ($max_shft1, $max_shft2) = @value;
     $tie = $value[2] if $#value > 1;
   } elsif ($opt eq "T") {
     ($m1, $m2) = @value;
   } elsif ($opt eq "U") {
     ($rupDir) = @value;
     $pVel = 6.4;
     $sVel = 3.6;
     $rise = 0.4;
     $appdx .= "_dir";
   } elsif ($opt eq "V") {
     ($vp, $love, $rayleigh) = @value;
   } elsif ($opt eq "W") {
     $disp = $value[0];
   } elsif ($opt eq "X") {
     $mltp = $value[0];
   } elsif ($opt eq "Y") {
     $ngf = 6;
     $eloc = $value[0] if $#value == 0;
   } elsif ($opt eq "Z") {
     $weight = $value[0];
   } else {
     printf STDERR $usage;
     exit(0);
   }
}
@event = grep(!/^-/,@ARGV);

if ( -r $dura ) {	# use a sac file for source time function   
  $dt = 0;
  $riseTime = 1;
} else {
  $rise = 0.5 if $rise>0.5;
  $riseTime = $rise*$dura;
}

($model, $depth) = split('_', $md_dep);
unless ($depth) {
  $model = ".";
  $depth = 1;
}

$ngf++ if $ngf == 3 and ($iso !=0. or $diso>0. or $clvd !=0. or $clvd>0.);

foreach $eve (@event) {

  next unless -d $eve;
  print STDERR "$eve $depth $dura\n";

  open(WEI, "$eve/$weight") || next;
  @wwf=<WEI>;
  close(WEI);
  $ncom = 2 if $wwf[0] =~ / -1 /;

  $cmd = "$cmd$appdx $eve $md_dep $eloc" unless $cmd eq "cat";
  print STDERR "$cmd\n";

  open(SRC, "| $cmd") || die "can not run $cmd\n";
  print SRC "$pVel $sVel $riseTime $dura $rupDir\n",$riseTime if $pVel;
  print SRC "$m1 $m2 $max_shft1 $max_shft2 $repeat $bootstrap $fm_thr $tie\n";
  print SRC "@thrshd\n" if $repeat;
  print SRC "$vpvs $mu\n";
  print SRC "$vp $love $rayleigh\n";
  print SRC "$power_of_body $power_of_surf $weight_of_pnl $nof\n";
  print SRC "$plot\n";
  print SRC "$disp $mltp\n";
  print SRC "$green/$model\n$ngf\n";
  print SRC "$dt $dura $riseTime\n";
  print SRC "$f1_pnl $f2_pnl $f1_sw $f2_sw\n";
  print SRC "$iso $diso\n";
  print SRC "$clvd $dclvd\n";
  print SRC "$str1 $str2 $deg\n";
  print SRC "$dip1 $dip2 $deg\n";
  print SRC "$rak1 $rak2 $deg\n";
  printf SRC "%d\n",$#wwf + 1;
  print SRC @wwf;
  close(SRC);
  print STDERR "inversion done\n";

  plot:
  if ( $plot > 0 && ($? >> 8) == 0 ) {
     chdir($eve);
     &plot($md_dep, $m1, $m2, $amplify, $ncom, $sec_per_inch);
     unlink(<${md_dep}_*.?>) unless $keep;
     chdir("../");
  }

}
exit(0);
