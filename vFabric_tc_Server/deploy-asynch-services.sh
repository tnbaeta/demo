#!/bin/sh

export webapps_dir="/opt/vmware/vfabric-tc-server-standard/springtrader/webapps"
export service_start="/opt/vmware/vfabric-tc-server-standard/springtrader/bin/tcruntime-ctl.sh start"
export service_stop="/opt/vmware/vfabric-tc-server-standard/springtrader/bin/tcruntime-ctl.sh stop"
export service_restart="/opt/vmware/vfabric-tc-server-standard/springtrader/bin/tcruntime-ctl.sh restart"

export instance=springtrader
export context=spring-nanotrader-asynch-services

export war_file=https://artifactory.slatchdev.local/artifactory/binrepo/springtrader/spring-nanotrader-asynch-services-1.0.1.war
wget --no-check-certificate $war_file
mv spring-nanotrader-asynch-services-1.0.1.war /tmp
export war_file=/tmp/spring-nanotrader-asynch-services-1.0.1.war

#Function to check the service status using the check of existance of pid file
# $1 = stop/start stop=check for service stop  start=check for the service start
checkServicestatus() {
    declare -i counter
    counter=0
    while [ $counter -lt 40 ]; do
        if [ $1 == "start" ] ; then
		  if [ -f "/opt/vmware/vfabric-tc-server-standard/$instance/logs/tcserver.pid" ] ; then
	           echo "tcServer service is in start state."
			   return
	      else
		       echo "Waiting for tcServer service to start."
		       counter=$counter+1
      	       sleep 5
          fi
		else
		  if [ -f "/opt/vmware/vfabric-tc-server-standard/$instance/logs/tcserver.pid" ] ; then
	           echo "Waiting for tcServer service to stop."
			   counter=$counter+1
      	       sleep 5
	      else
		       echo "tcServer service is in stop state."
		       return
          fi
        fi
    done
        echo "tcServer service is not in $1 state"
        exit 1
}

# Stop the application server. This parameter should point to the script used to stop the application server.
$service_stop
checkServicestatus "stop"

# Ensure that webapps_dir property is assigned to the application server webapps_dir property.
cp ${war_file} ${webapps_dir}/${context}.war

# Start the application server. This parameter should point to the script used to start the application server.
$service_start
checkServicestatus "start"
