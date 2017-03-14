#!/bin/bash

/bin/echo -e "\033[31mApplying patch1..Please Wait! \033[0m"

cluster_name=`curl -s  -u admin:admin -H "X-Requested-By: ambari" -X GET http://\`hostname\`:8080/api/v1/clusters|grep -i cluster_name |awk -F "\"" '{print $4}'`


#==========

echo "log4j.logger.org.eclipse.jetty.server.session=DEBUG" >> /etc/ambari-server/conf/log4j.properties
#/bin/sed -i 's:log4j.rootLogger=INFO,file:log4j.rootLogger=DEBUG,file:g' /etc/ambari-server/conf/log4j.properties
/bin/sed -i 's:log4j.appender.file.MaxFileSize=80MB:log4j.appender.file.MaxFileSize=1MB:g' /etc/ambari-server/conf/log4j.properties
/bin/sed -i 's:log4j.appender.file.MaxBackupIndex=60:log4j.appender.file.MaxBackupIndex=2:g' /etc/ambari-server/conf/log4j.properties

#==========

/bin/echo "alter role ambari Superuser;" | sudo -u postgres psql &>/tmp/role.log

sleep 2

/bin/echo "alter table serviceconfigmapping drop constraint fk_scvm_scv;" |PGPASSWORD='bigdata' psql -U ambari &>/tmp/scm.log

sleep 2

/bin/echo "alter table serviceconfigmapping add constraint fk_scvm_scv FOREIGN KEY (service_config_id) REFERENCES serviceconfig(service_config_id)  on delete cascade;" |PGPASSWORD='bigdata' psql -U ambari &>> /tmp/scm.log

sleep 2

/bin/echo "SELECT * FROM serviceconfig WHERE service_name='RANGER' and service_config_id NOT IN (SELECT service_config_id FROM ( SELECT service_config_id FROM serviceconfig ORDER BY service_config_id DESC LIMIT 1 ) foo );" |PGPASSWORD='bigdata' psql -U ambari &>/tmp/selectsc.log

sleep 2

/bin/echo "DELETE FROM serviceconfig WHERE service_name='RANGER' and service_config_id NOT IN (SELECT service_config_id FROM ( SELECT service_config_id FROM serviceconfig ORDER BY service_config_id DESC LIMIT 1 ) foo );" |PGPASSWORD='bigdata' psql -U ambari &>/tmp/deletesc.log

sleep 2

/usr/bin/mysql -u root -predhat -h `hostname` -e "update ranger.x_portal_user set password='643b28sdfsdf2d1d483fa0677ba63e0732fb' where first_name='amb_ranger_admin';"

sleep 2

curl -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop RANGER via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://`hostname`:8080/api/v1/clusters/$cluster_name/services/RANGER &>/tmp/out1

sleep 20

curl -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d  '{"RequestInfo": {"context" :"Start RANGER via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}'  http://`hostname`:8080/api/v1/clusters/$cluster_name/services/RANGER &>/tmp/out2

sleep 25

/etc/init.d/ambari-server restart &>/tmp/as_restart.log
rm -fr ./doSet*

/bin/echo -e "\033[32mPatch successfully applied \033[0m"
