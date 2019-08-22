#!/bin/sh
# vFabric ApplicationDirector START script for vFabric tc Server

export db_password=nanotrader
export db_username=nanotrader
export has_jvm_route=no
export instance_name=springtrader
export instance_root_dir=/opt/vmware/vfabric-tc-server-standard
export java_home=/usr/bin/java
export node_index=0
export node_ip=$(hostname -I)
export port=8080
export repo_host=repo.vmware.com
export repo_rpm=vfabric-5.1-repo-5.1-1.noarch.rpm
export templates=(bio)
export use_ajp=no
export version=5.1

export external_template=https://artifactory.slatchdev.local/artifactory/binrepo/springtrader/springtrader.tgz
wget --no-check-certificate $external_template
mv springtrader.tgz /tmp
export external_template=/tmp/springtrader.tgz

#RabbitMQ
echo "RabbitMQ Server IP = $rabbitmq_node_ip"
#echo "RabbitMQ Server Port = $rabbitmq_node_port"
export rabbitmq_node_port=5672

#SQLFire DB Info
echo "SQLFire Locator IP = $db_ip"
export db_port=1527
export jdbc_url=jdbc:sqlfire://${db_ip}:${db_port}/
echo "jdbc_url = $jdbc_url"

# This script simply starts the tc Server instance created in the tcserver-config.sh sample script. 

set -e

export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin
export HOME=/root
export tcserver_home=${tcserver_home:="/opt/vmware/vfabric-tc-server-standard"}

export JAVA_HOME=${java_home:="/usr"}

if [ -f ${tcserver_home}/${instance_name}/bin/tcruntime-ctl.sh ]; then
    $service_start
    IS_RUNNING=`/opt/vmware/vfabric-tc-server-standard/bin/tcruntime-ctl.sh status | grep Status | awk -F: '{ print $2 }'`
    if [[ "${IS_RUNNING}" == *"NOT RUNNING"* ]]; then
        echo "ERROR: ${tcserver_home}/${instance_name} is NOT RUNNING."
        echo "Please check the logs in ${tcserver_home}/${instance_name}/logs for more information"
        exit 1
    else
        echo "COMPLETED: The status of your new tc Server instance is: ${IS_RUNNING}"
    fi
fi
