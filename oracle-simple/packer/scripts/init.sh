#!/usr/bin/env bash

yum update -y
yum install -y epel-release
yum install -y -q ansible nfs-utils ccze

#Create sharedfs directory
mkdir -p /mnt/sharedfs

echo "Changing directory"
cd /home/opc/rpms
rpm -ivh oracle-instantclient12.1-*
echo /usr/lib/oracle/12.1/client64/lib/ >  /etc/ld.so.conf.d/oracle-instantclient.conf
ldconfig

#Disble the Selinux and Firewald
systemctl stop firewalld.service
systemctl disable firewalld.service

sed -i 's/enforcing/disabled/g' /etc/selinux/config