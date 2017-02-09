#!/bin/bash

/bin/echo -e "\033[31mApplying patch2..Please Wait! \033[0m"

sleep 2

/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p admin -port 8080 set node1.openstacklocal hdptest admin-properties "policymgr_external_url" " http://node1.openstacklocal:6080" &>/tmp/var_out2

/bin/echo "SELECT * FROM serviceconfig WHERE service_name='RANGER' and service_config_id NOT IN (SELECT service_config_id FROM ( SELECT service_config_id FROM serviceconfig ORDER BY service_config_id DESC LIMIT 1 ) foo );" |PGPASSWORD='bigdata' psql -U ambari &>/tmp/selectsc.log2

sleep 2

/bin/echo "DELETE FROM serviceconfig WHERE service_name='RANGER' and service_config_id NOT IN (SELECT service_config_id FROM ( SELECT service_config_id FROM serviceconfig ORDER BY service_config_id DESC LIMIT 1 ) foo );" |PGPASSWORD='bigdata' psql -U ambari &>/tmp/deletesc.log2

sleep 2

curl -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop RANGER via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://node1.openstacklocal:8080/api/v1/clusters/hdptest/services/RANGER &>/tmp/out2

sleep 15

curl -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop HDFS via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://node1.openstacklocal:8080/api/v1/clusters/hdptest/services/HDFS &>>/tmp/out2

sleep 15

curl -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d  '{"RequestInfo": {"context" :"Start RANGER via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}'  http://node1.openstacklocal:8080/api/v1/clusters/hdptest/services/RANGER &>>/tmp/out2

sleep 15

curl -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d  '{"RequestInfo": {"context" :"Start HDFS via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}'  http://node1.openstacklocal:8080/api/v1/clusters/hdptest/services/HDFS &>>/tmp/out2

sleep 15

session_id=`cat /var/log/ambari-server/ambari-server.log|grep "Got Session ID"|tail -n 1 |rev|cut -d' ' -f3|rev`
curl -u admin:admin -i -H 'X-Requested-By:ambari' -H "Cookie: AMBARISESSIONID=$session_id" -X GET http://node1.openstacklocal:8080/api/v1/logout &>/tmp/admin_logout
rm -fr ./doSet*


/bin/echo -e "\033[32mPatch successfully applied \033[0m"
