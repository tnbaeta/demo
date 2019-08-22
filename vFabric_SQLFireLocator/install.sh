#!/bin/bash

export java_home=/usr/bin/java
export install_path=/opt/vmware/darwin/sqlfire
export peer_discovery_port=10101
export repo_host=repo.vmware.com
export multicast_port=12333
export locator_client_port=1527

# vFabric ApplicationDirector Sample INSTALL script for vFabric sqlfire

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

checkStatus(){
   echo "Checking status "
   if [ $1 -ne 0 ];then
       echo "Execution failed"
       exit 1
   fi
}


proxy_host=`echo $http_proxy | sed -e 's_http://__' -e 's/:.*//'`
proxy_port=`echo $http_proxy | sed  -e 's/.*://'`

if [ ! $proxy_host == "" ]; then
    echo "setting http proxy macro in /usr/lib/rpm/macros"
    echo "" >>  /usr/lib/rpm/macros
    echo "%_httpproxy $proxy_host" >> /usr/lib/rpm/macros
fi

if [ ! $proxy_port == "" ]; then
    echo "setting http port macro in /usr/lib/rpm/macros"
    echo "" >>  /usr/lib/rpm/macros
    echo "%_httpport $proxy_port" >> /usr/lib/rpm/macros
fi


export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin
export VMWARE_HOME=/opt/vmware
export HOME=/root
export SQLFIRE_PACKAGE=vfabric-sqlfire
export SQLFIRE_VERSION=${GEMFIRE_VERSION:="103"}
export SQLFIRE_HOME=${SQLFIRE_HOME:="$VMWARE_HOME/$SQLFIRE_PACKAGE/vFabric_SQLFire_$SQLFIRE_VERSION"}
export EULA_LOCATION=${EULA_LOCATION:="http://www.vmware.com/download/eula/vfabric_app-platform_eula.html"}

env > /tmp/env.txt

# Any of the following may be set as Properties in your service definition, and if enabled, may be overwritten
# in your application blueprint.
export JAVA_HOME=${java_home:="/usr"}

# pre-set the license agreement for rpm
if [ ! -d "/etc/vmware/vfabric" ]; then
    mkdir -p /etc/vmware/vfabric
fi
echo "setting up vfabric repo"
echo "I_ACCEPT_EULA_LOCATED_AT=${EULA_LOCATION}" >> /etc/vmware/vfabric/accept-vfabric-eula.txt
echo "I_ACCEPT_EULA_LOCATED_AT=${EULA_LOCATION}" >> /etc/vmware/vfabric/accept-vfabric5.1-eula.txt

if [ -f /etc/redhat-release ] ; then
    DistroBasedOn='RedHat'
    DIST=`cat /etc/redhat-release |sed s/\ release.*//`
    REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*// | awk -F. '{ print $1 }'`
else
    echo "Installation only supported on RedHat and CentOS; exiting installation script"
    exit 1
fi


# setup repo
if [ -f /bin/rpm ]; then
   if [ "$REV" == "5" -o "$REV" == "6" ]; then
      if [ "$VERSION" == "latest" -o "$VERSION" == "" ]; then
          export VFABRIC_DATA=`wget -qO- http://${repo_host}/pub/rhel${REV}/vfabric/latest`
          export VERSION=`echo $VFABRIC_DATA | cut -d'|' -f1`
          export REPO_RPM=`echo $VFABRIC_DATA | cut -d'|' -f2`
      fi
      rpm -Uvh --force http://${repo_host}/pub/rhel${REV}/vfabric/${VERSION}/${REPO_RPM}
      checkStatus $?
   else
      echo "Unsupported version: ${REV}; exiting installation"
      exit
   fi
else
   echo "RPM utility not available; exiting installation script"
   exit 1
fi

if [  "$version" == "5.2" ]; then
      /etc/vmware/vfabric/vfabric-${version}-eula-acceptance.sh --accept_eula_file=VMware_EULA_20120515b_English.txt
      checkStatus $?
fi


if [ "$DistroBasedOn" == "RedHat" ]; then
   if [ "$DIST" == "CentOS" ]; then
      if [ -x /usr/sbin/selinuxenabled ] && /usr/sbin/selinuxenabled; then
         echo 'SELinux is enabled. This may cause installation to fail.'
      fi
   fi
   if [ -f /usr/bin/yum ]; then
      echo "Installing ${SQLFIRE_PACKAGE}"
      yum -y -v install ${SQLFIRE_PACKAGE}
      checkStatus $?
   else
      echo "ERROR! Unable to locate yum in ${PATH}; Exiting installer"
      exit 1
   fi
fi

if [ -f ${SQLFIRE_HOME}/bin/sqlf ]; then
   echo "COMPLETED: sqlfire has been installed in ${SQLFIRE_HOME}"
   echo "Please see https://www.vmware.com/support/pubs/vfabric-sqlfire.html for more information"
else
   echo "ERROR! SQLFire executable not found in ${SQLFIRE_HOME}; Exiting installer"
   exit
fi
# determine the vFabric SQLFire Locator VMs IP - this can either be a property specified in the service catalog (i.e."self:ip"),
# or we can determine it here
if [ "${locator_ip}" == "" ]; then
   export locator_ip=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
fi

export db_ip=${locator_ip}
export db_port=${locator_client_port}
export jdbc_url=jdbc:sqlfire://${db_ip}:${db_port}/
