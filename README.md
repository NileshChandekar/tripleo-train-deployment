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

root@617579-logging01:~# virsh net-list
 Name           State    Autostart   Persistent
-------------------------------------------------
 default        active   yes         yes
 provisioning   active   yes         yes
 vlannet        active   yes         yes

root@617579-logging01:~# virsh net-info provisioning
Name:           provisioning
UUID:           b646a663-1c4d-4399-a77b-eb9c461153b5
Active:         yes
Persistent:     yes
Autostart:      yes
Bridge:         provibr1

root@617579-logging01:~# 

root@617579-logging01:~# virsh net-info vlannet
Name:           vlannet
UUID:           abad710a-7ba7-4cb2-a50d-3334db101168
Active:         yes
Persistent:     yes
Autostart:      yes
Bridge:         vlanbr2

root@617579-logging01:~# 
```

|VLAN|NETWORK|IP|RANGE|
|----|----|----|----|
|FLAT|External|192.168.122.0/24|[{'start': '192.168.122.50', 'end': '192.168.122.100'}]|
