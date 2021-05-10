#!/bin/bash
: <<'ENDUSAGE'
sudo start_hpcc.sh
NOTE: THIS MUST BE EXECUTED BY ROOT
ENDUSAGE
myhome=/home/`basename $(pwd)`
echo /opt/HPCCSystems/sbin/hpcc-run.sh -a hpcc-init start
/opt/HPCCSystems/sbin/hpcc-run.sh -a hpcc-init start 2>&1|tee $myhome/start.log

# Check for failure
fail="TIMEOUT"
failed=0
while read line;do
  if [[ $line =~ $fail ]];then
     failed=1
     break
  fi
done < $myhome/start.log
echo "failed=\"$failed\""

if [ "$failed" == "1" ];then
  echo /opt/HPCCSystems/sbin/hpcc-run.sh -a hpcc-init -c thor stop
  /opt/HPCCSystems/sbin/hpcc-run.sh -a hpcc-init -c thor stop
  echo /opt/HPCCSystems/sbin/hpcc-run.sh -a hpcc-init -c thor start
  /opt/HPCCSystems/sbin/hpcc-run.sh -a hpcc-init -c thor start
  echo /opt/HPCCSystems/sbin/hpcc-run.sh -a hpcc-init restart
  /opt/HPCCSystems/sbin/hpcc-run.sh -a hpcc-init restart
fi


