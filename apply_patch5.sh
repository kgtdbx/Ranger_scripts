#!/bin/bash

/bin/echo -e "\033[31mApplying patch1..Please Wait! \033[0m"

/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p admin -port 8080 set node1.openstacklocal hdptest ranger-admin-site  "ranger.unixauth.remote.login.enabled" "false" &>/tmp/var_out1

/bin/echo "SELECT * FROM serviceconfig WHERE service_name='RANGER' and service_config_id NOT IN (SELECT service_config_id FROM ( SELECT service_config_id FROM serviceconfig ORDER BY service_config_id DESC LIMIT 1 ) foo );" |PGPASSWORD='bigdata' psql -U ambari &>/tmp/selectsc.log

/bin/echo "DELETE FROM serviceconfig WHERE service_name='RANGER' and service_config_id NOT IN (SELECT service_config_id FROM ( SELECT service_config_id FROM serviceconfig ORDER BY service_config_id DESC LIMIT 1 ) foo );" |PGPASSWORD='bigdata' psql -U ambari &>/tmp/deletesc.log

curl -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop RANGER via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://node1.openstacklocal:8080/api/v1/clusters/hdptest/services/RANGER &>/tmp/out1

sleep 10

curl -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d  '{"RequestInfo": {"context" :"Start RANGER via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}'  http://node1.openstacklocal:8080/api/v1/clusters/hdptest/services/RANGER &>/tmp/out1

/bin/echo -e "\033[32mPatch successfully applied \033[0m"
