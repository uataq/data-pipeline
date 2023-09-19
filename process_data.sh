#!/bin/bash
# Ben Fasoli

#JCL: source Lmod if it's not already sourced - cron starts in clean environment
if [ -z "$LMOD_VERSION" ]; then
  source /etc/profile.d/chpc.sh
fi

source $HOME/.custom.sh

#JCL: need to manually load the correct version of R
module load R/4.2.2

echo "Date: $(/usr/bin/date)"
echo "R binary: $(which Rscript)"

WD=/uufs/chpc.utah.edu/common/home/lin-group9/measurements/pipeline/
cd $WD
echo "Path: $WD"
echo

echo "Fetching remote updates..."
git pull
ssh-agent -k > /dev/null
echo

exec=$(ls run)
for i in ${exec[@]}; do
  echo "Running: $i..."
  lf=log/$(echo $i | cut -f 1 -d '.').log
  /usr/bin/nohup Rscript run/$i &>>$lf &
  pid=$!

  maxParallelWaitSeconds=600
  for j in $(seq 0 $maxParallelWaitSeconds); do
    sleep 1
    if ! ps -p $pid &>/dev/null; then
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
echo

# Build air.utah.edu
echo "Building air.utah.edu static source code..."
Rscript ../air.utah.edu/_render.r
echo

echo "Pushing database changes to webserver..."
 /usr/bin/rsync -aqvtzL --delete -e \
   '/usr/bin/ssh -i /uufs/chpc.utah.edu/common/home/u0791084/.ssh/id_rsa' \
   ../data/* u0791084@air.chpc.utah.edu:/data/
echo

echo "Pushing static webpages to VM..."
/usr/bin/rsync -aqvtzL -e '/usr/bin/ssh -i /uufs/chpc.utah.edu/common/home/u0791084/.ssh/id_rsa' \
   ../air.utah.edu/_site/* u0791084@air.chpc.utah.edu:/var/www/html/
