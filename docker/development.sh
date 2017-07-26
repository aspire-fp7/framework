#!/bin/bash
set -e
set -u

if [ ! -d /opt/development ]
then
  echo "/opt/development needs to be mounted!"
  exit -1
fi

rm /opt/framework
ln -s /opt/development /opt/framework

rsync -av --progress /opt/framework_buildtime/ /opt/framework/
