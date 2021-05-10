#!/bin/bash -e
#NOTE: This script should be run as root, i.e. prefix it with 'sudo'.
ThisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
sshuser=`basename $ThisDir`
echo "ENTERING $0. sshuser=\"$sshuser\""

#----------------------------------------------------------------------------------
# put all private ips, input as commandline arguments, in $ThisDir/private_ips.sh (master first)
# NOTE: First ip MUST be the master's followed by all roxie ips followed by all thor ips
# NOTE: There MUST be 3 numbers input before ips. The 1st MUST be the number of thor slaves, 
#       the 2nd MUST be the number of roxies, and the 3rd MUST be the slavesPerNode.
#----------------------------------------------------------------------------------

if [ -e "$ThisDir/private_ips.txt" ];then rm -v $ThisDir/private_ips.txt; fi
ivars=1
for var in "$@"
do
    # Check if this $var is a number. If so put it in 'thornodes' if 1st otherwise put in 'roxienodes'.
    if [[ $ivars -eq 1 ]];then
          thornodes=$var
    elif [[ $ivars -eq 2 ]];then
          roxienodes=$var
    elif [[ $ivars -eq 3 ]];then
          slavesPerNode=$var
    else # NOT a number so assume it is an IP address
       echo "$var" >> $ThisDir/private_ips.txt
    fi
    ivars=$((ivars+1))
done
echo "thornodes=$thornodes, roxienodes=$roxienodes"
cat $ThisDir/private_ips.txt|echo -

#----------------------------------------------------------------------------------
# Generate a new environment.xml file.
#----------------------------------------------------------------------------------
envgen=/opt/HPCCSystems/sbin/envgen;

created_environment_file=/etc/HPCCSystems/source/new_environment.xml
out_environment_file=/etc/HPCCSystems/environment.xml
private_ips=$ThisDir/private_ips.txt

# Make new environment.xml file for newly configured HPCC System.
echo $envgen  -env $created_environment_file -ipfile $private_ips -supportnodes 1 -thornodes $thornodes -roxienodes $roxienodes -slavesPerNode $slavesPerNode  -roxieondemand 1
$envgen  -env $created_environment_file -ipfile $private_ips -supportnodes 1 -thornodes $thornodes -roxienodes $roxienodes -slavesPerNode $slavesPerNode  -roxieondemand 1

# Change new environment.xml file's ownership to hpcc:hpcc
echo "chown hpcc:hpcc $created_environment_file"
chown hpcc:hpcc $created_environment_file

# For hpcc-push to work correctly, MUST cp the environment.xml file created above to $out_environment_file
echo cp -v $created_environment_file $out_environment_file
cp -v $created_environment_file $out_environment_file

#----------------------------------------------------------------------------------
# Use hpcc-push to push new environment.xml file to all instances.
#----------------------------------------------------------------------------------
echo /opt/HPCCSystems/sbin/hpcc-push.sh -s $created_environment_file -t $out_environment_file
/opt/HPCCSystems/sbin/hpcc-push.sh -s $created_environment_file -t $out_environment_file

#echo "Wait 30 seconds before starting cluster"
#sleep 30; 
