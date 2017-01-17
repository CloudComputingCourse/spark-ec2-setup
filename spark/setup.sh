#!/bin/bash

BIN_FOLDER="/root/spark/sbin"

# Copy the slaves to spark conf
cp /root/spark-ec2-setup/slaves /root/spark/conf/
/root/spark-ec2-setup/copy-dir /root/spark/conf

# Start Master
$BIN_FOLDER/start-master.sh

# Pause
sleep 20

# Start Workers
$BIN_FOLDER/start-slaves.sh
$BIN_FOLDER/start-history-server.sh