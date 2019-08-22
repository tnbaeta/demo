#!/bin/bash

export java_home=/usr/bin/java
export install_path=/opt/vmware/darwin/sqlfire
export peer_discovery_port=10101
export repo_host=repo.vmware.com
export multicast_port=12333
export locator_client_port=1527
export locator_ip=$(hostname -I)

# vFabric ApplicationDirector Sample START script for vFabric sqlfire

# This example uses the values posted below as defaults.   To change any of these
# values, add the Property Name as shown below as individual properties in your
# service definition in the ApplicationDirector Catalog.   The value specified after
# the Property name is the Type to use for the property (i.e. String, Content, Array etc)
# There are two types of properties for this script: Required and Optional.  Both are
# listed below.
#
# REQUIRED PROPERTIES:
# These are the properties you must add in order for this sample script to work. The property
# is added when you create your service definition in the ApplicationDirector Catalog.
# Property Description:                                Property Value settable in blueprint [type]:
# --------------------------------------------------------------------------------------------
# Location of global configuration data                global_conf [Content]
# value: https://${darwin.server.ip}:8443/darwin/conf/darwin_global.conf
#
# Version of vFabric Suite release                     VERSION [String]
# value: latest (to get most up to date version), 5.1, 5.2, etc
#
# If VERSION property is set to anything other then 'latest' then you need to set
# REPO_RPM property.
#
# File name of repository RPM for given version        REPO_RPM [String]
# value: example = vfabric-5.1-repo-5.1-1.noarch.rpm for 5.1 repo
#
# OPTIONAL PROPERTIES:
# Property Description:                                Property Name settable in blueprint:
# --------------------------------------------------------------------------------------------
# which java to use                                    JAVA_HOME [String]

export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin:$java_home/bin
export VMWARE_HOME=/opt/vmware
export HOME=/root
export SQLFIRE_PACKAGE=vfabric-sqlfire
export SQLFIRE_VERSION=${GEMFIRE_VERSION:="103"}
export SQLFIRE_HOME=${SQLFIRE_HOME:="$VMWARE_HOME/$SQLFIRE_PACKAGE/vFabric_SQLFire_$SQLFIRE_VERSION"}

# Any of the following may be set as Properties in your service definition, and if enabled, may be overwritten
# in your application blueprint.
export JAVA_HOME=${java_home:="/usr"}

export service_start=${service_start:="${SQLFIRE_HOME}/bin/sqlf  locator start"}
export service_stop=${service_stop:="${SQLFIRE_HOME}/bin/sqlf  locator stop"}

echo "service_start script:$service_start"
echo "service_stop script:$service_stop"

if [ -f ${SQLFIRE_HOME}/bin/sqlf ]; then
    echo "Creating Directories For New SQLFire Cluster Locator"
    cd ${SQLFIRE_HOME}
    su sqlfire -c 'rm -rf appd_locator'
    su sqlfire -c 'mkdir appd_locator'
    echo "Starting SQLFire Locator"
    echo "client port ${locator_client_port}"
    echo "locator node ip $locator_ip"
    export node_ip=$locator_ip
    export locator_ip
    export locator_client_port=$locator_client_port
    cd ${SQLFIRE_HOME}/bin
    echo "Running Command---> su sqlfire -c 'sqlf locator start -dir=${SQLFIRE_HOME}/appd_locator -peer-discovery-address=${node_ip} -peer-discovery-port=${peer_discovery_port} -client-bind-address=${node_ip} -client-port=${locator_client_port} -J-Dsqlfire.prefer-netserver-ipaddress=true'"
    su sqlfire -c 'sqlf locator start -dir=${SQLFIRE_HOME}/appd_locator -peer-discovery-address=${node_ip} -peer-discovery-port=${peer_discovery_port} -client-bind-address=${node_ip} -client-port=${locator_client_port} -J-Dsqlfire.prefer-netserver-ipaddress=true'
    ##### sqlf locator start -dir=appd_locator -peer-discovery-address=10.150.108.21 -peer-discovery-port=10101 -client-bind-address=10.150.108.21 -client-port=1527  -J-Dsqlfire.prefer-netserver-ipaddress=true
    status=`su sqlfire -c 'sqlf locator status -dir=${SQLFIRE_HOME}/appd_locator | grep running'`
    if [ -n "$status" ]; then
       echo "SQLFire Locator Started"
    else
       echo "SQLFire Locator Failed to start"
       exit 1
    fi
   #cd ${SQLFIRE_HOME}/quickstart
   #echo "Loading Data Into Tables"
   #su sqlfire -c 'sqlf run -file=ToursDB_schema.sql'
   #su sqlfire -c 'sqlf run -file=loadTables.sql'
else
   echo "ERROR! SQLFire executable not found in ${SQLFIRE_HOME}; Exiting"
   exit
fi