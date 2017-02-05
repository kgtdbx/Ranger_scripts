#!/bin/bash

/bin/echo -e "\033[31mApplying patch1..Please Wait! \033[0m"

/bin/echo "alter role ambari Superuser;" | sudo -u postgres psql &>/tmp/role.log

/bin/echo "alter table serviceconfigmapping drop constraint fk_scvm_scv;" |PGPASSWORD='bigdata' psql -U ambari &>/tmp/scm.log

/bin/echo "alter table serviceconfigmapping add constraint fk_scvm_scv FOREIGN KEY (service_config_id) REFERENCES serviceconfig(service_config_id)  on delete cascade;" |PGPASSWORD='bigdata' psql -U ambari &>> /tmp/scm.log

/bin/echo "SELECT * FROM serviceconfig WHERE service_name='RANGER' and service_config_id NOT IN (SELECT service_config_id FROM ( SELECT service_config_id FROM serviceconfig ORDER BY service_config_id DESC LIMIT 1 ) foo );" |PGPASSWORD='bigdata' psql -U ambari &>/tmp/selectsc.log

/bin/echo "DELETE FROM serviceconfig WHERE service_name='RANGER' and service_config_id NOT IN (SELECT service_config_id FROM ( SELECT service_config_id FROM serviceconfig ORDER BY service_config_id DESC LIMIT 1 ) foo );" |PGPASSWORD='bigdata' psql -U ambari &>/tmp/deletesc.log

/usr/bin/mysql -u root -predhat -e "update ranger.x_portal_user set password='643b28sdfsdf2d1d483fa0677ba63e0732fb' where first_name='amb_ranger_admin';"

curl -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop RANGER via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://node1.openstacklocal:8080/api/v1/clusters/hdptest/services/RANGER &>/tmp/out1

sleep 15

curl -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d  '{"RequestInfo": {"context" :"Start RANGER via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}'  http://node1.openstacklocal:8080/api/v1/clusters/hdptest/services/RANGER &>/tmp/out2

/bin/echo -e "\033[32mPatch successfully applied \033[0m"
