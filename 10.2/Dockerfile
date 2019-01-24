# Pull from original-image
FROM mariadb:10.2

# Setting up environtment settings
ENV REPLICATION_USER replication
ENV REPLICATION_PASSWORD replication_pass
ENV MYSQL_MONITORING_PASSWORD=monitorpass

# Copy files
COPY replication-entrypoint.sh /usr/local/bin/
COPY init-slave.sh /
COPY my-tweak.cnf /etc/mysql/conf.d/

# install some additional tools
RUN apt-get update
RUN apt-get install -y vim iputils-ping net-tools

# Entry-point
ENTRYPOINT ["replication-entrypoint.sh"]

# Execute service
CMD ["mysqld"]
