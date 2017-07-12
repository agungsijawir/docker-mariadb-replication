#!/bin/bash
export MYSQL_ROOT_PASSWORD=foopass
echo 'create `test` schema and populate some data'
cat 02-master-database.sql | docker exec -i db_master mysql -p"${MYSQL_ROOT_PASSWORD}"

echo "check slaves to ensure that data was replicated"
for run in {1..2}; do
  container_name=db_slave${run}
  echo "###### ${container_name} ######"
  docker exec -it "${container_name}" mysql -p"${MYSQL_ROOT_PASSWORD}" -e 'select * from test.test'
done

echo "mysql_secure_installation diagnostics:"
declare -a arr=("db_master" "db_slave1" "db_slave2")
for container_name in "${arr[@]}"; do
  echo "###### ${container_name} ######"
  docker exec -it "${container_name}" mysql -p"${MYSQL_ROOT_PASSWORD}" -e "select count(*) as is_root_wildcard_user_present from mysql.user where user='root' and host='%'\G"
done