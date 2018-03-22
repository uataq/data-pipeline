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
exec=$(ls run)
echo

# Spawn parallel R child processes
for i in ${exec[@]}; do
  echo "Spawning: $i"
  lf=log/$(echo $i | cut -f 1 -d '.').log
  echo "Run: `date`" > $lf
  Rscript run/$i &>> $lf &
done

# Wait for processing to finish (max ~4 minutes)
sleep 5
echo "Awaiting process completion..."
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
echo "Building air.utah.edu static source code..."
# Rscript air.utah.edu/_build.r

echo "Pushing air.utah.edu changes to webserver..."
# rsync -az _site/* benfasoli@air.utah.edu:/var/www/html/
# rsync -az _site ~/public_html/air.utah.edu

echo "Pushing database changes to webserver..."
rsync -az ../data benfasoli@air.utah.edu:/projects/data-beta
