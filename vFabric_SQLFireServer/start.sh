#!/bin/bash

export client_bind_address=$(hostname -I)
export client_port=1528
export initial_heap=512m
export java_home=/usr/bin/java
export max_heap=1024m
export multicast_port=12333
export node_index=0
export number_of_servers=1
export password=nanotrader
export repo_host=repo.vmware.com
export username=nanotrader

#From Locator
export locator_client_port=1527
echo "Locator IP = $locator_ip"
export peer_discovery_port=10101

#Node Index
echo "Node Index = $node_index"

#wget these
export dataload_file=https://artifactory.slatchdev.local/artifactory/binrepo/nanotrader-dataload.sql
export schema_file=https://artifactory.slatchdev.local/artifactory/binrepo/nanotrader-schema.sql

wget --no-check-certificate $dataload_file
mv nanotrader-dataload.sql /tmp
export dataload_file=/tmp/nanotrader-dataload.sql

wget --no-check-certificate $schema_file
mv nanotrader-schema.sql /tmp
export schema_file=/tmp/nanotrader-schema.sql

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
export service_start=${service_start:="${SQLFIRE_HOME}/bin/sqlf server start"}
export service_stop=${service_stop:="${SQLFIRE_HOME}/bin/sqlf server stop"}
export service_stop_all=${service_stop_all:="${SQLFIRE_HOME}/bin/sqlf shut-down-all"}

echo "service_start:$service_start"
echo "service_stop:$service_stop"
echo "service_stop_all:$service_stop_all"

if [ -f ${SQLFIRE_HOME}/bin/sqlf ]; then
    echo "Creating Directories For New SQLFire Cluster"
    cd ${SQLFIRE_HOME}
    for ((i=0; i<$number_of_servers; i++)) 
    do
       count=$(($i + 1))
       echo "count:$count"
       directory_name="appd_server"
       directory_name=$directory_name$count
       echo "directory_name:$directory_name"
       echo "Starting SQLFire Server$count"
       echo "locator client port:$locator_client_port"
       echo "locator node ip:$locator_ip"
       my_client_port=$(($client_port + $i))
       echo "my_client_port:$client_port"
       #su sqlfire -c 'rm -rf $directory_name'
       #su sqlfire -c 'mkdir $directory_name'
       rm -rf $directory_name
       mkdir $directory_name
       sqlf server start -dir=${SQLFIRE_HOME}/$directory_name -locators=${locator_ip}[${peer_discovery_port}] -client-bind-address=${client_bind_address} -client-port=$my_client_port -initial-heap=$initial_heap -max-heap=$max_heap -J-Dsqlfire.prefer-netserver-ipaddress=true 
       #status=`su sqlfire -c 'sqlf server status -dir=${SQLFIRE_HOME}/$directory_name | grep running'`
       status=`sqlf server status -dir=${SQLFIRE_HOME}/$directory_name | grep running`
       if [ -n "$status" ]; then
          echo "SQLFire Server$count Started"
       else
          echo "SQLFire Server$count Failed to start"
          exit 1
       fi
   done
   # execute user-provided sql file against sqlfire
   # only run schema against the very first sqlfire server node

   echo "node_index:$node_index"
   echo "schemafile:$schema_file"
   echo "dataload_file:$dataload_file"
   schema=`basename ${schema_file}`
   data=`basename ${dataload_file}`

   export username=${username}
   export password=${password}

   if [ "$node_index" == "0" ]; then
      echo "first sqlfire server node detected"
      if [ -f ${schema_file} -a ${schema##*.} == "sql" ]; then
          echo "Running schema file"
          echo "Loading schema ${schema_file} on ${locator_ip}" 
          if [ ! $username == "" ]; then
          echo "authentication used"
          echo "username:$username"
          echo "password:$password"
          ${SQLFIRE_HOME}/bin/sqlf > sqlf-schema.log << EOF
          connect client '${locator_ip}:${locator_client_port};user=$username;password=$password';
          run '${schema_file}';
          exit;
EOF
        else
          echo "no authentication used"
          ${SQLFIRE_HOME}/bin/sqlf > sqlf-schema.log << EOF
          connect client '${locator_ip}:${locator_client_port}';
          run '${schema_file}';
          exit;
EOF
      fi
      fi
        if [ -f ${dataload_file} -a ${data##*.} == "sql" ]; then
          echo "Running dataload file"
          echo "Loading schema ${dataload_file} on ${locator_ip}"
          if [ ! $username == "" ]; then 
          echo "authentication used"
          echo "username:$username"
          echo "password:$password"
          ${SQLFIRE_HOME}/bin/sqlf > sqlf-dataload.log << EOF
          connect client '${locator_ip}:${locator_client_port};user=$username;password=$password';
          run '${dataload_file}';
          exit;
EOF
       else
          echo "no authentication required"
          ${SQLFIRE_HOME}/bin/sqlf > sqlf-dataload.log << EOF
          connect client '${locator_ip}:${locator_client_port}';
          run '${dataload_file}';
          exit;
EOF
      fi
     fi
   else
      echo "no user-provided sql executed. non first sqlfire server node detected"
   fi
else
   echo "ERROR! SQLFire executable not found in ${SQLFIRE_HOME}; Exiting"
   exit
fi