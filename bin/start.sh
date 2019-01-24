#!/bin/bash
set -x
export MYSQL_ROOT_PASSWORD=foopass
export MYSQL_MONITORING_PASSWORD=monitorpass
docker-compose up
#sleep 5
#docker logs db_master
#echo "#######################################################"
#docker logs db_slave1
