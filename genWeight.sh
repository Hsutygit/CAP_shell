#!/bin/bash
cd ./rotate/
saclst dist t1 f *.z*   | awk '{gsub(".z","",$1); printf "%s %d %s %.1f %s\n", $1,$2,"1 1 1 1 1",$3,"0"}' | sort -n --key=2 > weight.dat

