#!/bin/bash

for j in 5
do
cap3D.pl -D2/1/0.5 -T35/70 -P0.135/50 -H0.05 -MMenyuan_$j/4.0 -W1 -X10 -R0/360/0/90/-90/90  -S2/5/0 -C0.02/0.2/0.02/0.1 -I5/0.1 -G.  rotate

done


cd ./rotate
gmt psconvert -Tf *.ps
rm *.ps
