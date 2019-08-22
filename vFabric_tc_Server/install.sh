#!/bin/sh

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

env
env >> env.txt

# vFabric ApplicationDirector Sample INSTALL script for vFabric tc Server 

# This example uses the values posted below as defaults.   To change any of these
# values, add the Property Name as shown below as individual properties in your 
# service definition in the ApplicationDirector Catalog.   The value specified after
# the Property name is the Type to use for the property (i.e. String, Content, Array etc)
# There are two types of properties for this script: Required and Optional.  Both are 
# listed below.
#
# REQUIRED PROPERTIES:
# Property Name                   Type        Default Value
# -----------------------------------------------------------------------------------------------------------
# global_conf                     Content     https://${darwin.server.ip}:8443/darwin/conf/darwin_global.conf
# version                         String      latest
# repo_rpm                        String      [null] when version = latest
#                                             example = vfabric-5.1-repo-5.1-1.noarch.rpm for version = 5.1
# node_ip                         String      self:ip
# port                            String      8080
# deployment_unit_url             Content     
# instance_name                   String
# webapp_dir                      String
# instance_dir                    String
# service_start                   Computed
# service_stop                    Computed
# service_restart                 Computed
# has_jvm_route                   String
# templates                       Array
# java_home                       String

# Check the exit status
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
export tcserver_home=${tcserver_home:="/opt/vmware/vfabric-tc-server-standard"}
export JAVA_HOME=${java_home:="/usr"}
export EULA_LOCATION=${EULA_LOCATION:="http://www.vmware.com/download/eula/vfabric_app-platform_eula.html"}

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
      if [ "$version" == "latest" -o "$version" == "" ]; then
          export VFABRIC_DATA=`wget -qO- http://${repo_host}/pub/rhel${REV}/vfabric/latest`
          export version=`echo $VFABRIC_DATA | cut -d'|' -f1`
          export repo_rpm=`echo $VFABRIC_DATA | cut -d'|' -f2`
      fi
      rpm -Uvh --force http://${repo_host}/pub/rhel${REV}/vfabric/${version}/${repo_rpm}
      checkStatus $?
   else
      echo "Unsupported version: ${REV}; exiting installation"
      exit 1
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
       for (( i = 0 ; i < 5 ; i++ )); do
           yum -y -v install ${tcserver_home}
           if [ $? -eq 0 ];then
               break
           fi
           echo "Execution failed $i"
           sleep 10
       done
       if [ $i -eq 5 ]; then
           echo "Execution failed"
           exit 1
       fi
   else
      echo "ERROR! Unable to locate yum in ${PATH}; exiting installer"
      exit 1
   fi
fi

if [ -f ${tcserver_home} ]; then
   echo "COMPLETED: tc Server ${version} has been installed under ${tcserver_home}"
   echo "Please see https://www.vmware.com/support/pubs/vfabric-tcserver.html for more information"
fi

export instance_dir=${instance_root_dir}/${instance_name}

# determine the vFabric tc Server VMs IP - this can either be a property specified in the service catalog (i.e."self:ip"),
# or we can determine it here
if [ "${node_ip}" == "" ]; then
   export node_ip=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
fi
