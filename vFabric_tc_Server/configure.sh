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

# vFabric ApplicationDirector CONFIG script for vFabric tc Server
# Set the computed property values so that they have the values when exposed

export server_node_index=$node_index
export server_node_ip=$node_ip

export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin
export HOME=/root
export tcserver_home=${tcserver_home:="/opt/vmware/vfabric-tc-server-standard"}
#export JAVA_HOME=${java_home:="/usr"}
export JAVA_HOME=/usr
export instance_name=${instance_name:="vfabric-tc-server-sample"}
export node_ip=${node_ip:="10.10.1.1"}

if [ -f ${tcserver_home}/${instance_name} ]; then
    echo "ERROR: The directory ${tcserver_home}/${instance_name} already exists and we will not overwrite it. Exiting script"
    exit 1
fi

# Create instance root directory
mkdir -p $instance_root_dir

DBUSER=""
DBPASS=""
JDBCURL=""
echo "db_username:$db_username"
echo "db_password:$db_password"
template_filename=`basename ${external_template}`
echo "template_filename:$template_filename"
# Download and expand external_template
#if [ -f ${external_template} -a ${template_filename##*.} == "tgz" ]; then
    echo "Found external template..."
    pushd .
    cd ${tcserver_home}/templates
    TEMPLS="-t ""`basename ${external_template} | sed 's/\.tgz$//' | sed 's/\.tar.gz$//'`"
    TNAME="`basename ${external_template} | sed 's/\.tgz$//' | sed 's/\.tar.gz$//'`"
    if [ ! $db_username == "" ]; then
        DBUSER="-p${TNAME}.${TNAME}.username=${db_username}"
    fi
    if [ ! $db_password == "" ]; then
        DBPASS="-p${TNAME}.${TNAME}.password=${db_password}"
    fi
    if [ "$jdbc_url" != "" ]; then
        JDBCURL="-p${TNAME}.${TNAME}.url=${jdbc_url}"
    fi
    echo "Using these properties: $PORTS $DBUSER $DBPASS $JDBCURL"
    echo "external template:$external_template"
    tar -zvxf $external_template
    popd
#fi

# create a tc Server instance.
if [ -f ${tcserver_home}/tcruntime-instance.sh ]; then
    # construct strings with all templates and ports to supply as an argument to instance create command
    echo "Constucting tc Server command options...."
    for (( i = 0 ; i < ${#templates[@]} ; i++ )); do
        TEMPLS="$TEMPLS"" -t ${templates[$i]}"
        PORTS="$PORTS"" -p${templates[$i]}.http.port=${port}"
    done
    echo "Using these templates: ${TEMPLS}"
    echo "Using these properties: $PORTS $DBUSER $DBPASS $JDBCURL"

    # create new instance under instance_root_dir
    echo "Creating tc Server instance: ${instance_name}, Under directory:  ${instance_root_dir}"
    if [ $use_ajp == "yes" ]; then
        echo "${tcserver_home}/tcruntime-instance.sh create ${instance_name} ${TEMPLS} -t ajp --instance-directory ${instance_root_dir} $PORTS $DBUSER $DBPASS $JDBCURL"
        ${tcserver_home}/tcruntime-instance.sh create ${instance_name} ${TEMPLS} -t ajp --instance-directory ${instance_root_dir} $PORTS $DBUSER $DBPASS $JDBCURL
    else
        echo "${tcserver_home}/tcruntime-instance.sh create ${instance_name} ${TEMPLS} --instance-directory ${instance_root_dir} $PORTS $DBUSER $DBPASS $JDBCURL -pspringtrader.springtrader.driverClassName=com.vmware.sqlfire.jdbc.ClientDriver -pspringtrader.springtrader.spring.profiles.active=production,jndi -pspringtrader.springtrader.validationQuery=select 1 from nanotrader.hibernate_sequences where sequence_name=\'ACCOUNT\'"
        ${tcserver_home}/tcruntime-instance.sh create ${instance_name} ${TEMPLS} --instance-directory ${instance_root_dir} $PORTS $DBUSER $DBPASS $JDBCURL -pspringtrader.springtrader.driverClassName=com.vmware.sqlfire.jdbc.ClientDriver -pspringtrader.springtrader.spring.profiles.active=production,jndi "-pspringtrader.springtrader.validationQuery=select 1 from nanotrader.hibernate_sequences where sequence_name='ACCOUNT'"
    fi
    echo "COMPLETED: A new tc Server instance has been created in ${tcserver_home}/${instance_name}"
    echo "List of templates applied : ${templates[@]}"
else  
    echo "ERROR: tc Server ${version} is been installed in ${tcserver_home}"
    echo "ERROR: please run tc-server installation script first. Exiting CONFIGURE"
    exit 1
fi

export webapps_dir="/opt/vmware/vfabric-tc-server-standard/springtrader/webapps"
export service_start="/opt/vmware/vfabric-tc-server-standard/springtrader/bin/tcruntime-ctl.sh start"
export service_stop="/opt/vmware/vfabric-tc-server-standard/springtrader/bin/tcruntime-ctl.sh stop"
export service_restart="/opt/vmware/vfabric-tc-server-standard/springtrader/bin/tcruntime-ctl.sh restart"
export instance_dir="/opt/vmware/vfabric-tc-server-standard/springtrader"


# Add the jvmRoute attr to the Engine 
if [ -f $instance_dir/conf/server.xml -a ${has_jvm_route} == "yes" ]; then
    echo "Setting jvmRoute to ${node_index} for sticky session configuration on load balancer"
    sed -ie "s/\(Engine defaultHost=\"localhost\"\)$/\1 jvmRoute=\"${node_index}\"/" ${instance_dir}/conf/server.xml 
fi

# Add Database IP to catalina.properties
if [ ! $db_ip == "" ]; then
    echo "Setting Database IP config at catalina.properties"
    echo "" >> ${instance_dir}/conf/catalina.properties
    echo "db_ip=${db_ip}" >> ${instance_dir}/conf/catalina.properties
fi

# Add Database Port to catalina.properties
if [ ! $db_port == "" ]; then
    echo "Setting Database Port config at catalina.properties"
    echo "" >> ${instance_dir}/conf/catalina.properties
    echo "db_port=${db_port}" >> ${instance_dir}/conf/catalina.properties
fi

# Add jdbc_url to catalina.properties
if [ ! $jdbc_url == "" ]; then
    echo "Setting jdbc_url=${jdbc_url} in catalina.properties"
    echo "" >> ${instance_dir}/conf/catalina.properties
    echo "jdbc_url=${jdbc_url}" >> ${instance_dir}/conf/catalina.properties
fi

# Add NANO_RABBIT_HOST to catalina.properties
if [ ! $rabbitmq_node_ip == "" ]; then
    echo "Setting NANO_RABBIT_HOST config at catalina.properties"
    echo "" >> ${instance_dir}/conf/catalina.properties
    echo "NANO_RABBIT_HOST=${rabbitmq_node_ip}" >> ${instance_dir}/conf/catalina.properties
fi

# Add NANO_RABBIT_PORT to catalina.properties
if [ ! $rabbitmq_node_port == "" ]; then
    echo "Setting NANO_RABBIT_PORT config at catalina.properties"
    echo "" >> ${instance_dir}/conf/catalina.properties
    echo "NANO_RABBIT_PORT=${rabbitmq_node_port}" >> ${instance_dir}/conf/catalina.properties
fi