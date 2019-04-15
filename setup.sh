#!/bin/bash

# Sometimes the apt-get in the following line fails with 
# Could not get /var/lib/dpkg/lock - open (11: Resource temporarily unavailable)
# This might mitigate that
sleep 5

# pssh install usually fails so exepct this to fail as well; not needed
# left here for historic reasons
sudo apt-get install -y -q pssh


# Check if the previous command executed successfully
# apt_ret=0
# for attempt in `seq 1 5`
# do
  # echo "Trying to install pssh, attempt $attempt"
  # sudo apt-get install -y -q pssh
  # apt_ret=$?

  # if [[ $apt_ret == 0 ]]
  # then
    # echo "pssh installed successfully."
    # break
  # fi
# done

# if [[ $apt_ret != 0 ]]
# then
  # echo "********************************************"
  # echo "Unable to install pssh. Something broke within the Spark Cluster"
  # echo "Please destroy this cluster manually from AWS GUI"
  # echo "And try to respawn it."
  # echo "********************************************"
  # exit 255
# fi

# usage: echo_time_diff name start_time end_time
echo_time_diff () {
  local format='%Hh %Mm %Ss'

  local diff_secs="$(($3-$2))"
  echo "[timing] $1: " "$(date -u -d@"$diff_secs" +"$format")"
}

# Make sure we are in the spark-ec2-setup directory
pushd /root/spark-ec2-setup > /dev/null

# Load the environment variables specific to this AMI
source /root/.bash_profile

# Load the cluster variables set by the deploy script
source ec2-variables.sh

# Set hostname based on EC2 private DNS name, so that it is set correctly
# even if the instance is restarted with a different private DNS name
PRIVATE_DNS=`wget -q -O - http://169.254.169.254/latest/meta-data/local-hostname`
PUBLIC_DNS=`wget -q -O - http://169.254.169.254/latest/meta-data/hostname`
hostname $PRIVATE_DNS
echo $PRIVATE_DNS > /etc/hostname
export HOSTNAME=$PRIVATE_DNS  # Fix the bash built-in hostname variable too

echo "Setting up Spark on `hostname`..."

# Set up the masters, slaves, etc files based on cluster env variables
echo "$MASTERS" > masters
echo "$SLAVES" > slaves

MASTERS=`cat masters`
NUM_MASTERS=`cat masters | wc -l`
OTHER_MASTERS=`cat masters | sed '1d'`
SLAVES=`cat slaves`
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

if [[ "x$JAVA_HOME" == "x" ]] ; then
    echo "Expected JAVA_HOME to be set in .bash_profile!"
    exit 1
fi

if [[ `tty` == "not a tty" ]] ; then
    echo "Expecting a tty or pty! (use the ssh -t option)."
    exit 1
fi

echo "Setting executable permissions on scripts..."
find . -regex "^.+.\(sh\|py\)" | xargs chmod a+x

echo "RSYNC'ing /root/spark-ec2-setup to other cluster nodes..."
rsync_start_time="$(date +'%s')"
for node in $SLAVES $OTHER_MASTERS; do
  echo $node
  rsync -e "ssh $SSH_OPTS" -az /root/spark-ec2-setup $node:/root &
  scp $SSH_OPTS ~/.ssh/id_rsa $node:.ssh &
  sleep 0.1
done
wait
rsync_end_time="$(date +'%s')"
echo_time_diff "rsync /root/spark-ec2-setup" "$rsync_start_time" "$rsync_end_time"

echo "Running setup-slave on all cluster nodes to mount filesystems, etc..."
setup_slave_start_time="$(date +'%s')"
parallel-ssh --inline \
    --host "$MASTERS $SLAVES" \
    --user root \
    --extra-args "-t -t $SSH_OPTS" \
    --timeout 0 \
    "spark-ec2-setup/setup-slave.sh $1"
setup_slave_end_time="$(date +'%s')"
echo_time_diff "setup-slave" "$setup_slave_start_time" "$setup_slave_end_time"

# Deploy templates
# TODO: Move configuring templates to a per-module ?
echo "Creating local config files..."
/root/spark-ec2-setup/deploy_templates.py

# Copy spark conf by default
echo "Deploying Spark config files..."
chmod u+x /root/spark/conf/spark-env.sh
/root/spark-ec2-setup/copy-dir /root/spark/conf

# Setup each module
for module in $MODULES; do
  echo "Setting up $module"
  module_setup_start_time="$(date +'%s')"
  source ./$module/setup.sh
  sleep 0.1
  module_setup_end_time="$(date +'%s')"
  echo_time_diff "$module setup" "$module_setup_start_time" "$module_setup_end_time"
  cd /root/spark-ec2-setup  # guard against setup.sh changing the cwd
done

popd > /dev/null
