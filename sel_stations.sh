cd rotate
saclst stlo stla f *.z*   | awk '{gsub(".00.z","",$1); printf "%.3f   %.3f   %s\n", $2,$3,$1}' > station_names.dat