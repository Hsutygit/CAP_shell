#!/bin/bash

#rename
rm -rf data_rename
mkdir data_rename

cp data_raw/*.SAC ./data_rename/
cd ./data_rename/

file=$(ls *.SAC)
for filename in $file
do
        F=$(echo $filename | cut -b 24-42)
        echo $F
        mv $filename $F
done

#label the arrive time for P and S
taup_setsac -ph p-1,P-1,Pdiff-1,s-3,S-3,Sdiff-3 -evdpkm -model ak135 *.SAC