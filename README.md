# tripleo-train-deployment



![logo](https://github.com/NileshChandekar/tripleo-train-deployment/blob/main/tripleologo.png)


### Networks
* First let's talk through networking setup. In my lab I created 6 VLANs for OpenStack to utilize.

|Role|
|----|
|Baremetal Node|

```
root@617579-logging01:~# virsh net-list
 Name           State    Autostart   Persistent
-------------------------------------------------
 default        active   yes         yes
 provisioning   active   yes         yes
 vlannet        active   yes         yes

root@617579-logging01:~# 
```

```
root@617579-logging01:~# virsh net-info default
Name:           default
UUID:           5f706fab-ffb8-44a5-b85e-a24c8c0eebdd
Active:         yes
Persistent:     yes
Autostart:      yes
Bridge:         virbr0
```

```
root@617579-logging01:~# virsh net-info provisioning
Name:           provisioning
UUID:           b646a663-1c4d-4399-a77b-eb9c461153b5
Active:         yes
Persistent:     yes
Autostart:      yes
Bridge:         provibr1
```

```
root@617579-logging01:~# 

root@617579-logging01:~# virsh net-info vlannet
Name:           vlannet
UUID:           abad710a-7ba7-4cb2-a50d-3334db101168
Active:         yes
Persistent:     yes
Autostart:      yes
Bridge:         vlanbr2
```


```
root@617579-logging01:~# virsh net-dumpxml default
<network connections='3'>
  <name>default</name>
  <uuid>5f706fab-ffb8-44a5-b85e-a24c8c0eebdd</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:bc:d5:7e'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

```
root@617579-logging01:~# virsh net-dumpxml provisioning
<network>
  <name>provisioning</name>
  <uuid>b646a663-1c4d-4399-a77b-eb9c461153b5</uuid>
  <bridge name='provibr1' stp='on' delay='0'/>
  <mac address='52:54:00:8c:cd:cd'/>
  <ip address='192.168.24.254' netmask='255.255.255.0'>
  </ip>
</network>
```

```
root@617579-logging01:~# virsh net-dumpxml vlannet
<network>
  <name>vlannet</name>
  <uuid>abad710a-7ba7-4cb2-a50d-3334db101168</uuid>
  <bridge name='vlanbr2' stp='on' delay='0'/>
  <mac address='52:54:00:00:70:3b'/>
</network>
```



|VLAN|NETWORK|IP|RANGE|NetworkInfo|Gateway|
|----|----|----|----|----|----|
|FLAT|External|192.168.122.0/24|[{'start': '192.168.122.2', 'end': '192.168.122.254'}]|default|192.168.122.1|
|FLAT|Provisioning|192.168.24.0/24|NOT DEFINED|provisioning|192.168.24.1|
|20|Internal API|172.16.2.0/24|[{'start': '172.16.2.4', 'end': '172.16.2.250'}]|vlannet|----|
|30|Storage|172.16.1.0/24|[{'start': '172.16.1.4', 'end': '172.16.1.250'}]|vlannet|----|
|40|Storage|172.16.3.0/24|[{'start': '172.16.3.4', 'end': '172.16.3.250'}]|vlannet|----|
|50|Tenant|172.16.0.0/24|[{'start': '172.16.0.4', 'end': '172.16.0.250'}]|vlannet|----|

### Hardware

* In order to deploy RDO, you will need a decent amount of hardware available. OpenStack is a cloud software stack and to be useful, it requires some resources.


|Role|
|----|
|Baremetal Node|


|Memory|CPU|HDD|
|----|----|----|
|128GB|24|2TB|



|Role|
|----|
|Virtual Machine|


|Node Name|Memory|CPU|HDD|
|----|----|----|----|
|Undercloud|16GB|6|100GB|
|Controller-0|18GB|6|100GB|
|Compute-0|18GB|6|100GB|


```
root@617579-logging01:~# virsh list --all
 Id   Name          State
------------------------------
 8    undercloud    running
 50   root-cmpt-0   running
 51   root-ctrl-0   running
root@617579-logging01:~# 
```

### Networking for your different nodes

*Undercloud* needs interfaces on provisioning and external networks. 

```
root@617579-logging01:~# virsh domiflist undercloud
 Interface   Type      Source     Model    MAC
--------------------------------------------------------------
 vnet0       bridge    provibr1   virtio   52:54:00:3b:d8:b6
 vnet1       network   default    virtio   52:54:00:9e:6f:5b

root@617579-logging01:~# 
```

*Controllers* need interfaces on all networks (provisioning), (vlan), (external)

```
root@617579-logging01:~# virsh domiflist root-ctrl-0
 Interface   Type      Source     Model    MAC
--------------------------------------------------------------
 vnet5       bridge    provibr1   virtio   52:54:00:bf:9c:d3
 vnet6       bridge    vlanbr2    virtio   52:54:00:9a:cb:47
 vnet7       network   default    virtio   52:54:00:f6:aa:f4

root@617579-logging01:~# 
```

*Computes* need interfaces on all networks (provisioning), (vlan), (external - optional)

```
root@617579-logging01:~# virsh domiflist root-cmpt-0
 Interface   Type      Source     Model    MAC
--------------------------------------------------------------
 vnet2       bridge    provibr1   virtio   52:54:00:21:d6:e5
 vnet3       bridge    vlanbr2    virtio   52:54:00:b0:24:38
 vnet4       network   default    virtio   52:54:00:6d:f1:47

root@617579-logging01:~# 
```

### Deploying the Undercloud

```
hostnamectl set-hostname undercloud-0.example.local
hostnamectl set-hostname --transient undercloud-0.example.local
echo "127.0.0.1 undercloud-0.example.local undercloud-0" >> /etc/hosts
```

```
useradd stack
echo stack | passwd --stdin stack
echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack
clear
su - stack
```

```
curl -O https://trunk.rdoproject.org/centos8/component/tripleo/current/python3-tripleo-repos-0.1.1-0.20220620133357.8321b3f.el8.noarch.rpm
```

```
sudo rpm -ivh python3-tripleo-repos-0.1.1-0.20220620133357.8321b3f.el8.noarch.rpm
```

```
sudo -E tripleo-repos -b train current ceph
```

```
sudo yum install -y python3-tripleoclient
```

```
sudo reboot
```
```
su - stack
```

```
openstack tripleo container image prepare default   --local-push-destination   --output-env-file containers-prepare-parameter.yaml
```

```
echo -e "[DEFAULT]
container_images_file = /home/stack/containers-prepare-parameter.yaml
local_interface = eth0
local_ip = 192.168.24.1/24
undercloud_public_host = 192.168.24.2
undercloud_admin_host = 192.168.24.3
undercloud_ntp_servers=0.in.pool.ntp.org

[ctlplane-subnet]
local_subnet = ctlplane-subnet
cidr = 192.168.24.0/24
dhcp_start = 192.168.24.5
dhcp_end = 192.168.24.24
gateway = 192.168.24.1
inspection_iprange = 192.168.24.100,192.168.24.120
masquerade = true
#TODO(skatlapa): add param to override masq" > ~/undercloud.conf
```

```
openstack undercloud install
```

### Preparing for the Overcloud Deployment


```
mkdir ~/images
mkdir ~/templates
cd  ~/images
```

```
source ~/stackrc
curl -O https://images.rdoproject.org/train/rdo_trunk/current-tripleo/overcloud-full.tar
curl -O https://images.rdoproject.org/train/rdo_trunk/current-tripleo/ironic-python-agent.tar
```

```
tar -xvf overcloud-full.tar
tar -xvf ironic-python-agent.tar 
```

```
openstack overcloud image upload --image-path /home/stack/images/
```

```
vi instackenv.json
```

```
[stack@undercloud-0 ~]$ cat instackenv.json 
{
"nodes": [
{
"pm_user": "admin",
"mac": ["52:54:00:bf:9c:d3"],
"pm_type": "pxe_ipmitool",
"pm_port": "6232",
"pm_password": "redhat",
"pm_addr": "192.168.24.254",
"capabilities" : "node:ctrl-0,boot_option:local",
"name": "overcloud-controller-0"
},

{
"pm_user": "admin",
"mac": ["52:54:00:21:d6:e5"],
"pm_type": "pxe_ipmitool",
"pm_port": "6230",
"pm_password": "redhat",
"pm_addr": "192.168.24.254",
"capabilities" : "node:cmpt-0,boot_option:local",
"name": "overcloud-compute-0"
}

]
}
[stack@undercloud-0 ~]$ 
```

```
openstack overcloud node import /home/stack/instackenv.json  
openstack overcloud node introspect --all-manageable --provide
```

```
[stack@undercloud-0 ~]$ cat v1_deploy.sh 
#!/bin/bash
time openstack overcloud deploy --templates /usr/share/openstack-tripleo-heat-templates/ \
-r /home/stack/templates/roles_data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /home/stack/templates/nic-config/network-environment.yaml \
-e /home/stack/containers-prepare-parameter.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/podman.yaml \
-e /home/stack/templates/rendered/environments/podman-ha.yaml \
-e /home/stack/templates/extra/node-info.yaml \
-e /home/stack/templates/extra/scheduler_hints_env.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-ovs.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/disable-telemetry.yaml \
--libvirt-type qemu \
--debug \
--log-file /tmp/install_overcloud.log \
--timeout 90

[stack@undercloud-0 ~]$ 
```

