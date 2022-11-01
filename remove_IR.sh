#!/bin/bash
rm -rf data_pre
mkdir data_pre
cp ./data_rename/*.SAC ./data_pre/
cp ../resp/* ./data_pre/

cd ./data_pre

sac << EOD
r *SAC
rtr
rmean
rtr
taper
trans from evalresp to vel freq 0.001 0.005 2 8

#from nm/s to cm/s
mul 1.0e-7 

w over

quit
EOD

rm RESP*

cd ..
