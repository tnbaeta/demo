#!/bin/sh
export TOMCAT_HOME=/opt/vmware/vfabric-tc-server-standard/springtrader
export war_file=https://artifactory.slatchdev.local/artifactory/binrepo/jolokia-war-1.6.0.war

wget --no-check-certificate $war_file
mv jolokia-war-1.6.0.war jolokia.war
mv jolokia.war /${TOMCAT_HOME}/webapps

sleep 15

/opt/vmware/vfabric-tc-server-standard/springtrader/bin/tcruntime-ctl.sh restart

sudo yum -y install epel-release
sudo yum -y install python-pip

sudo bash -c "$(curl -sL https://wavefront.com/install)" -- install \
    --agent \
    --proxy-address wavefrontcp.slatchdev.local \
    --proxy-port 2878


cat > /etc/telegraf/telegraf.d/tomcat.conf <<EOF
[[inputs.jolokia2_agent]]
urls = ["http://localhost:8080/jolokia"]
name_prefix = "tomcat."

### JVM Generic

[[inputs.jolokia2_agent.metric]]
name  = "OperatingSystem"
mbean = "java.lang:type=OperatingSystem"
paths = ["ProcessCpuLoad","SystemLoadAverage","SystemCpuLoad"]

[[inputs.jolokia2_agent.metric]]
name  = "jvm_runtime"
mbean = "java.lang:type=Runtime"
paths = ["Uptime"]

[[inputs.jolokia2_agent.metric]]
name  = "jvm_memory"
mbean = "java.lang:type=Memory"
paths = ["HeapMemoryUsage", "NonHeapMemoryUsage", "ObjectPendingFinalizationCount"]

[[inputs.jolokia2_agent.metric]]
name     = "jvm_garbage_collector"
mbean    = "java.lang:name=*,type=GarbageCollector"
paths    = ["CollectionTime", "CollectionCount"]
tag_keys = ["name"]

[[inputs.jolokia2_agent.metric]]
name       = "jvm_memory_pool"
mbean      = "java.lang:name=*,type=MemoryPool"
paths      = ["Usage", "PeakUsage", "CollectionUsage"]
tag_keys   = ["name"]
tag_prefix = "pool_"

### TOMCAT

[[inputs.jolokia2_agent.metric]]
name     = "GlobalRequestProcessor"
mbean    = "Catalina:name=*,type=GlobalRequestProcessor"
paths    = ["requestCount","bytesReceived","bytesSent","processingTime","errorCount"]
tag_keys = ["name"]

[[inputs.jolokia2_agent.metric]]
name     = "JspMonitor"
mbean    = "Catalina:J2EEApplication=*,J2EEServer=*,WebModule=*,name=jsp,type=JspMonitor"
paths    = ["jspReloadCount","jspCount","jspUnloadCount"]
tag_keys = ["J2EEApplication","J2EEServer","WebModule"]

[[inputs.jolokia2_agent.metric]]
name     = "ThreadPool"
mbean    = "Catalina:name=*,type=ThreadPool"
paths    = ["maxThreads","currentThreadCount","currentThreadsBusy"]
tag_keys = ["name"]

[[inputs.jolokia2_agent.metric]]
name     = "Servlet"
mbean    = "Catalina:J2EEApplication=*,J2EEServer=*,WebModule=*,j2eeType=Servlet,name=*"
paths    = ["processingTime","errorCount","requestCount"]
tag_keys = ["name","J2EEApplication","J2EEServer","WebModule"]

[[inputs.jolokia2_agent.metric]]
name     = "Cache"
mbean    = "Catalina:context=*,host=*,name=Cache,type=WebResourceRoot"
paths    = ["hitCount","lookupCount"]
tag_keys = ["context","host"]
EOF

sudo service telegraf restart 