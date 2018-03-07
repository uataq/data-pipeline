#!/bin/bash
# Ben Fasoli

# Import paths from .bash_profile
source $HOME/.bash_profile

# Set working directory
WD=/uufs/chpc.utah.edu/common/home/lin-group2/measurements-beta/proc/
cd $WD
echo "Initializing processing in $WD"
echo

# Fetch remote updates
echo "Fetching remote updates..."
git pull
echo

# Execute site processing scripts
# EXEC=$(ls run)
exec=(dbk.r heb.r imc.r lgn.r rpk.r sug.r sun.r)
echo "Spawning: ${exec[@]}"
echo

# Spawn parallel R child processes
for i in ${exec[@]}; do
  Rscript run/$i &
done

# Wait for processing to finish (max ~4 minutes)
sleep 10
maxit=2400
for i in $(seq 0 $maxit); do
  nrun=$(ls .lock | wc -l)
  if [ $nrun -gt 0 ]; then
    sleep 0.1
  else
    break
  fi
done

# Build air.utah.edu
echo "Building air.utah.edu source code..."
cd web
# Rscript _build.r

echo "Pushing air.utah.edu changes to webserver..."
# rsync -az _site/* benfasoli@air.utah.edu:/var/www/html/
