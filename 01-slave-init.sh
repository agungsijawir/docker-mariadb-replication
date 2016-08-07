#!/bin/bash
# TODO: master-data needs RELOAD privilege
# TODO: replace with replica user (read-only)
# TODO: blacklist? information_schema performance_schema
# TODO: cover slave side selection for replication entities:
# * replicate-do-db=db_name only if we want to store and replicate certain DBs
# * replicate-ignore-db=db_name used when we don't want to replicate certain DBs
# * replicate_wild_do_table used to replicate tables based on wildcard patterns
# * replicate_wild_ignore_table used to ignore tables in replication based on wildcard patterns 

# Expects these variables to be set
MASTER_USER=${MASTER_USER:-replication}
MASTER_PASSWORD=${MASTER_PASSWORD:-replication_pass}
MASTER_PORT=${MASTER_PORT:-3306}
MASTER_HOST=${MASTER_HOST:-master}
HEALTH_GRACE_PERIOD=${HEALTH_GRACE_PERIOD:-3}
HEALTH_TIMEOUT=${HEALTH_TIMEOUT:-10}

check_slave_health () {
  echo Checking replication health:
  status=$(mysql -u root -e "SHOW SLAVE STATUS\G")
  echo "$status" | egrep 'Slave_(IO|SQL)_Running:|Seconds_Behind_Master:|Last_.*_Error:' | grep -v "Error: $"
  if ! echo "$status" | grep -qs "Slave_IO_Running: Yes"    ||
     ! echo "$status" | grep -qs "Slave_SQL_Running: Yes"   ||
     ! echo "$status" | grep -qs "Seconds_Behind_Master: 0" ; then
	echo WARNING: Replication is not healthy.
    return 1
  fi
  return 0
}


echo Updating master connetion info in slave.

mysql -u root -e "RESET MASTER; \
  CHANGE MASTER TO \
  MASTER_HOST='$MASTER_HOST', \
  MASTER_PORT=$MASTER_PORT, \
  MASTER_USER='$MASTER_USER', \
  MASTER_PASSWORD='$MASTER_PASSWORD';"

mysqldump \
  --protocol=tcp \
  --user=$MASTER_USER \
  --password=$MASTER_PASSWORD \
  --host=$MASTER_HOST \
  --port=$MASTER_PORT \
  --hex-blob \
  --all-databases \
  --add-drop-database \
  --master-data \
  --flush-logs \
  --flush-privileges \
  | mysql -u root

echo mysqldump completed.

echo Starting slave ...
mysql -u root -e "START SLAVE;"

echo Initial health check:
check_slave_health

echo Waiting for health grace period and slave to be still healthy:
sleep $HEALTH_GRACE_PERIOD

counter=0
while ! check_slave_health; do
  if (( counter >= $HEALTH_TIMEOUT )); then
    echo ERROR: Replication not healthy, health timeout reached, failing.
	break
    exit 1
  fi
  let counter=counter+1
  sleep 1
done
