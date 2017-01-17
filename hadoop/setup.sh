#!/bin/bash

pushd /root/spark-ec2-setup/hadoop > /dev/null

cp /root/spark-ec2-setup/slaves /root/hadoop/etc/hadoop/
/root/spark-ec2-setup/copy-dir /root/hadoop/etc/hadoop/
mkdir -p /vol1/hadoop.tmp

NAMENODE_DIR="/vol1/hadoop.tmp/dfs/name"
PERSISTENT_HDFS=/root/hadoop

if [ -f "$NAMENODE_DIR/current/VERSION" ]; then
  echo "Hadoop namenode appears to be formatted: skipping"
else
  echo "Formatting HDFS namenode..."
  $PERSISTENT_HDFS/bin/hdfs namenode -format
fi

$PERSISTENT_HDFS/sbin/start-dfs.sh

popd > /dev/null
