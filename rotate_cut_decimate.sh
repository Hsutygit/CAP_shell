#!/bin/bash

rm -rf rotate
mkdir rotate

cd ./data_pre/

file=$(ls *BHZ*)
for filename in $file
do
E=$(echo $filename | sed 's/BHZ/BHE/g')
N=$(echo $filename | sed 's/BHZ/BHN/g')

R=$(echo $filename | sed 's/BHZ.D.SAC/r/g')
T=$(echo $filename | sed 's/BHZ.D.SAC/t/g')
Z=$(echo $filename | sed 's/BHZ.D.SAC/z/g')


sac << EOD

#rotate
r $N $E
rotate to gcp
w $R $T

r $filename
w $Z

#decimate and cut

r $T
decimate 5
cut o 0 300
rtr
rmean
rtr
taper
w $T

r $Z
decimate 5
cut o 0 300
rtr
rmean
rtr
taper
w $Z

r $R
decimate 5
cut o 0 300
rtr
rmean
rtr
taper
w $R

r $T
cut o 0 300
rtr
rmean
rtr
taper
w $T


quit
EOD

done

mv *r *t *z ../rotate

#generate the weight.dat file
cd ../rotate
saclst dist t1 f *.z*   | awk '{gsub(".z","",$1); printf "%s %d %s %.1f %s\n", $1,$2,"1 1 1 1 1",$3,"0"}' | sort -n --key=2 > weight.dat