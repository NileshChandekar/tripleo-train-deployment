# tripleo-train-deployment



![logo](https://github.com/NileshChandekar/tripleo-train-deployment/blob/main/tripleo.jpeg)


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

