#!/bin/bash
# Ben Fasoli

source /uufs/chpc.utah.edu/common/home/u0791983/.bashrc

echo "Date: $(/usr/bin/date)"
echo "R binary: $(which Rscript)"

WD=/uufs/chpc.utah.edu/common/home/lin-group2/measurements/pipeline/
cd $WD
echo "Path: $WD"
echo

echo "Fetching remote updates..."
git pull
echo


exec=$(ls run)
for i in ${exec[@]}; do
  echo "Running: $i..."
  lf=log/$(echo $i | cut -f 1 -d '.').log
  /usr/bin/nohup Rscript run/$i &>> $lf &
  pid=$!

  maxParallelWaitSeconds=600
  for j in $(seq 0 $maxParallelWaitSeconds); do
    sleep 1
    if ! ps -p $pid &> /dev/null; then
      break
    fi
  done
done

# Wait for processing to finish
# sleep 5
# echo "Awaiting process completion..."
# maxit=2400
# maxit=99999
# for i in $(seq 0 $maxit); do
#   nrun=$(ls .lock | wc -l)
#   if [ $nrun -gt 0 ]; then
#     sleep 0.1
#   else
#     break
#   fi
# done

# Build air.utah.edu
echo "Building air.utah.edu static source code..."
Rscript ../air.utah.edu/_render.r

echo "Pushing database changes to webserver..."
/usr/bin/rsync -aqvtz --delete -e \
  '/usr/bin/ssh -i /uufs/chpc.utah.edu/common/home/u0791983/.ssh/id_rsa' \
  ../data/* benfasoli@air.utah.edu:/projects/data/
