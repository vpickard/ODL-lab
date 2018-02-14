[[local|localrc]]
# put the log files in a dir different than the source so they can be manipulated independently
LOGFILE=/opt/stack/logs/stack.sh.log
SCREEN_LOGDIR=/opt/stack/logs
LOG_COLOR=False
# flip OFFLINE and RECLONE to lock (RECLONE=no) or update the source.
OFFLINE=True
RECLONE=no
#OFFLINE=False
#RECLONE=yes
VERBOSE=True

# disable everything so we can explicitly enable only what we need
disable_all_services

# Core compute (glance+keystone+nova+vnc)
enable_service dstat g-api g-reg key n-api n-meta-api n-cauth n-cond n-crt n-obj n-sch n-cpu n-novnc n-xvnc

# neutron services. Recognize q-agt and q-l3 is not set which means ODL is the l2 agent and l3 provider.
enable_service q-dhcp q-meta q-svc horizon
enable_service placement-api l2gw-plugin

# enable one of the two below:
# the first is external which assumes the user has ODL running already
# make sure to set the ODL_MGR_IP and ODL_PORT because we run in manual mode
# the second is allinone where devstack will download (if online) and start ODL
enable_service odl-compute odl-neutron

# or use the allinone
#enable_service odl-server odl-compute

# additional services. rabbit for rpm-based vm.
enable_service mysql rabbit

HOST_IP=10.8.125.250
HOST_NAME=odl250
SERVICE_HOST_NAME=$HOST_NAME
SERVICE_HOST=$HOST_IP
Q_HOST=$SERVICE_HOST

MYSQL_HOST=$SERVICE_HOST
RABBIT_HOST=$SERVICE_HOST
GLANCE_HOSTPORT=$SERVICE_HOST:9292
KEYSTONE_AUTH_HOST=$SERVICE_HOST
KEYSTONE_SERVICE_HOST=$SERVICE_HOST


ODL_MODE=manual
#ODL_MODE=allinone
#ODL_RELEASE=boron-snapshot-0.5.2
#ODL_NETVIRT_KARAF_FEATURE=odl-netvirt-openstack,odl-dlux-all
# PORT and IP are only needed if using manual mode with external ODL. allinone uses defaults.
ODL_PORT=8080
ODL_MGR_IP=10.8.125.250
ODL_USING_EXISTING_JAVA=False
ODL_PORT_BINDING_CONTROLLER=pseudo-agentdb-binding
ODL_OVS_MANAGERS=10.8.125.250,10.8.125.251,10.8.125.252
ODL_JAVA_MAX_MEM=2048m
ODL_V2DRIVER=True

SKIP_OVS_INSTALL=True

VNCSERVER_PROXYCLIENT_ADDRESS=$HOST_IP
VNCSERVER_LISTEN=0.0.0.0

DATABASE_PASSWORD=mysql
RABBIT_PASSWORD=rabbit
QPID_PASSWORD=rabbit
SERVICE_TOKEN=service
SERVICE_PASSWORD=admin
ADMIN_PASSWORD=admin


enable_plugin networking-odl http://git.openstack.org/openstack/networking-odl stable/pike


#### SR-IOV setup ####

# ML2 Configuration
Q_PLUGIN=ml2
Q_ML2_PLUGIN_MECHANISM_DRIVERS=sriovnicswitch,openvswitch,opendaylight

Q_ML2_PLUGIN_TYPE_DRIVERS=vlan,flat,local,vxlan
Q_ML2_TENANT_NETWORK_TYPE=vxlan
ML2_VLAN_RANGES=physnet1:2901:2909

# l2gw plugin
enable_plugin networking-l2gw http://git.openstack.org/openstack/networking-l2gw stable/pike
NETWORKING_L2GW_SERVICE_DRIVER=L2GW:OpenDaylight:networking_odl.l2gateway.driver.OpenDaylightL2gwDriver:default

# use master for latest
BRANCH=stable/pike
#BRANCH=master
GLANCE_BRANCH=$BRANCH
HORIZON_BRANCH=$BRANCH
KEYSTONE_BRANCH=$BRANCH
NOVA_BRANCH=$BRANCH
NEUTRON_BRANCH=$BRANCH
SWIFT_BRANCH=$BRANCH
##CLIFF_BRANCH=$BRANCH
##TEMPEST_BRANCH=$BRANCH
CINDER_BRANCH=$BRANCH
HEAT_BRANCH=$BRANCH
TROVE_BRANCH=$BRANCH
CEILOMETER_BRANCH=$BRANCH


[[post-config|$NOVA_CONF]]
[DEFAULT]
scheduler_default_filters=RamFilter,ComputeFilter,AvailabilityZoneFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,PciPassthroughFilter,AggregateInstanceExtraSpecsFilter
scheduler_available_filters=nova.scheduler.filters.all_filters

# ML2 plugin bits for SR-IOV enablement of Intel 82599 NIC - find this via lspci -nn | grep -A5 Eth .. use VF, not PF
[[post-config|/$Q_PLUGIN_CONF_FILE]]
[ml2_sriov]
supported_pci_vendor_devs = 8086:10ed

[[post-config|$NEUTRON_CONF]]
[DEFAULT]
service_plugins = odl-router_v2, networking_l2gw.services.l2gateway.plugin.L2GatewayPlugin

[[post-config|/etc/neutron/plugins/ml2/ml2_conf.ini]]
[agent]
minimize_polling=True

# workaround for port-status not working due to https://bugs.opendaylight.org/show_bug.cgi?id=9092
[ml2_odl]
odl_features=nothing

[[post-config|/etc/neutron/dhcp_agent.ini]]
[DEFAULT]
force_metadata = True
enable_isolated_metadata = True

[[post-config|/etc/nova/nova.conf]]
[DEFAULT]
force_config_drive = False

[scheduler]
discover_hosts_in_cells_interval = 30
