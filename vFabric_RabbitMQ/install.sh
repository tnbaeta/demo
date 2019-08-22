#!/bin/sh
#set -e

export rabbitmq_node_ip=$(hostname -I)
export rhel_repo=http://mirror.centos.org/centos/5/os
export rabbitmq_node_port=5672
export install_tar=https://artifactory.slatchdev.local/artifactory/binrepo/vfabric-rabbit-install-2.4.1.tar.gz

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export HOME=/root
export https_proxy=$http_proxy

wget --no-check-certificate $install_tar
mv vfabric-rabbit-install-2.4.1.tar.gz /tmp
export install_tar=/tmp/vfabric-rabbit-install-2.4.1.tar.gz

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

#Start checking OS type
echo "Starting OS check"
KERNEL=`uname -r`
MACH=`uname -m`
if [ -f /etc/redhat-release ] ; then
   DistroBasedOn='RedHat'
   DIST=`cat /etc/redhat-release |sed s/\ release.*//`
   REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
elif [ -f /etc/debian_version ] ; then
   DistroBasedOn='Debian'
   DIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
   REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
fi

if [ $DistroBasedOn == "Debian" ] ; then
   sed -i "10ideb http://www.rabbitmq.com/debian/ testing main" /etc/apt/sources.list
   echo $DistroBasedOn
   echo $http_proxy
   apt-get -f -y update
   apt-get -f -y --force-yes install 
   wget $debian_signing_public_key
   apt-key add rabbitmq-signing-key-public.asc
   apt-get -f -y --force-yes install rabbitmq-server
   
elif [ $DistroBasedOn == "RedHat" ] ; then
    if [ "$DIST" = "CentOS" ] ; then
       
       if [ -x /usr/sbin/selinuxenabled ] && /usr/sbin/selinuxenabled; then
             echo 'SELinux is enabled. This may cause installation to fail.'
       fi
       
       cd `dirname $install_tar`
       tar xvfz $install_tar
       cd vF-rabbit-install
       sed -i 's/  resolve_epel_erlang_repo/  #resolve_epel_erlang_repo/' ./rabbitmq_rhel.py

       TYPE_MATCH=`uname -p`
       if [ $MACH == "i686" ] ; then
           echo "32 bit machine"
           sed -i 's/^[^#].*epel-release-5-4.noarch.rpm\"/epel_rpm=\"http:\/\/dl.fedoraproject.org\/pub\/epel\/6\/i386\/epel-release-6-8.noarch.rpm\"/g' ./rabbitmq_rhel.py
       else
           echo "64 bit machine"
           sed -i 's/^[^#].*epel-release-5-4.noarch.rpm\"/epel_rpm=\"http:\/\/dl.fedoraproject.org\/pub\/epel\/6\/x86_64\/epel-release-6-8.noarch.rpm\"/g' ./rabbitmq_rhel.py
       fi

       echo "installing RabbitMQ"
       ./rabbitmq_rhel.py --setup-rabbitmq < /dev/console
       ./rabbitmq_rhel.py --start < /dev/console

    elif [ "$DIST" = "Red Hat Enterprise Linux Server" ] ; then
       echo "inside"
       echo $REV | grep -q '6.'
       if [ $? -eq 0 ] ; then
         echo "Red Hat Enterprise Linux Server 6 ...."
          TYPE_MATCH=`uname -p`
          if [ $MACH == "i686" ] ; then
            echo "32 bit machine"
            wget $rhel_repo/i386/CentOS/unixODBC-libs-2.2.11-10.el5.i386.rpm
            rpm -ivh unixODBC-libs-2.2.11-10.el5.i386.rpm
            wget $rhel_repo/i386/CentOS/unixODBC-2.2.11-10.el5.i386.rpm
            rpm -ivh unixODBC-2.2.11-10.el5.i386.rpm
          else
            echo "64 bit machine"
            wget $rhel_repo/x86_64/CentOS/unixODBC-libs-2.2.11-10.el5.x86_64.rpm
            rpm -ivh unixODBC-libs-2.2.11-10.el5.x86_64.rpm
            wget $rhel_repo/x86_64/CentOS/unixODBC-2.2.11-10.el5.x86_64.rpm
            rpm -ivh unixODBC-2.2.11-10.el5.x86_64.rpm
          fi

          cd `dirname $install_tar`
          tar xvfz $install_tar
          cd vF-rabbit-install
          sed -i 's/^[^#].*epel-release-5-4.noarch.rpm\"/epel_rpm=\"http:\/\/dl.fedoraproject.org\/pub\/epel\/5\/i386\/epel-release-5-4.noarch.rpm\"/g' ./rabbitmq_rhel.py

          echo "installing RabbitMQ" 
         ./rabbitmq_rhel.py --setup-rabbitmq < /dev/console
         ./rabbitmq_rhel.py --start < /dev/console
      fi
    fi 
fi
#End checking OS type
export rabbitmq_node_ip=$node_ip
echo "host:$rabbitmq_node_ip"
echo "port:$rabbitmq_node_port"