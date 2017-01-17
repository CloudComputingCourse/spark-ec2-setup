#!/bin/bash

# Disable Transparent Huge Pages (THP)
# THP can result in system thrashing (high sys usage) due to frequent defrags of memory.
# Most systems recommends turning THP off.
if [[ -e /sys/kernel/mm/transparent_hugepage/enabled ]]; then
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi

# Make sure we are in the spark-ec2 directory
pushd /root/spark-ec2-setup > /dev/null

source ec2-variables.sh

# Set hostname based on EC2 private DNS name, so that it is set correctly
# even if the instance is restarted with a different private DNS name
PRIVATE_DNS=`wget -q -O - http://169.254.169.254/latest/meta-data/local-hostname`
hostname $PRIVATE_DNS
echo $PRIVATE_DNS > /etc/hostname
HOSTNAME=$PRIVATE_DNS  # Fix the bash built-in hostname variable too

echo "checking/fixing resolution of hostname"
bash /root/spark-ec2-setup/resolve-hostname.sh

echo "Setting up slave on `hostname`... of type $instance_type"

# Format & mount using ext4
EXT4_MOUNT_OPTS="defaults,noatime,nodiratime"
rm -rf /vol1
mkdir /vol1
# To turn TRIM support on, uncomment the following line.
#echo '/dev/xvdb /mnt  ext4  defaults,noatime,nodiratime,discard 0 0' >> /etc/fstab
mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 /dev/xvds
mount -o $EXT4_MOUNT_OPTS /dev/xvds /vol1

# Make data dirs writable by non-root users, such as CDH's hadoop user
chmod -R a+w /vol1

# Remove ~/.ssh/known_hosts because it gets polluted as you start/stop many
# clusters (new machines tend to come up under old hostnames)
# rm -f /root/.ssh/known_hosts

# Create swap space on /mnt
/root/spark-ec2-setup/create-swap.sh $SWAP_MB

# Allow memory to be over committed. Helps in pyspark where we fork
echo 1 > /proc/sys/vm/overcommit_memory

# Add github to known hosts to get git@github.com clone to work
# TODO(shivaram): Avoid duplicate entries ?
# cat /root/spark-ec2-setup/github.hostkey >> /root/.ssh/known_hosts

# Create /usr/bin/realpath which is used by R to find Java installations
# NOTE: /usr/bin/realpath is missing in CentOS AMIs. See
# http://superuser.com/questions/771104/usr-bin-realpath-not-found-in-centos-6-5
echo '#!/bin/bash' > /usr/bin/realpath
echo 'readlink -e "$@"' >> /usr/bin/realpath
chmod a+x /usr/bin/realpath

popd > /dev/null

# this is to set the ulimit for root and other users
echo '* soft nofile 1000000' >> /etc/security/limits.conf
echo '* hard nofile 1000000' >> /etc/security/limits.conf