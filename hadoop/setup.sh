#!/bin/bash

pushd /root/spark-ec2-setup/hadoop > /dev/null

cp /root/spark-ec2-setup/slaves /root/hadoop/etc/hadoop/conf
/root/spark-ec2-setup/copy-dir /root/hadoop/etc/hadoop/conf
mkdir -p /vol1/hadoop.tmp

NAMENODE_DIR="/vol1/hadoop.tmp/dfs/name"
PERSISTENT_HDFS=/root/hadoop

if [ -f "$NAMENODE_DIR/current/VERSION" ] then
  echo "Hadoop namenode appears to be formatted: skipping"
else
  echo "Formatting ephemeral HDFS namenode..."
  $PERSISTENT_HDFS/bin/hdfs namenode -format
fi

$PERSISTENT_HDFS/bin/start-dfs.sh

popd > /dev/null
