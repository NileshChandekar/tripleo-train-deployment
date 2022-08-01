#!/bin/bash
clear


read -p "Enter Controller Count: " ctrl
read -p "Enter Compute Count: " cmpt

read -p "Enter Controller Memory Size: " mem_ctrl
read -p "Enter Compute Memory Size: " mem_cmpt

echo -e "\033[1;36mCreating Directories\033[0m"
user=$(id | awk '{print $1}' | sed 's/.*(//;s/)$//')

mkdir /openstack/images
mkdir /openstack/images/txtfiles
cd /openstack/images/ 


echo  -e "\033[42;5m Step_2: Start libvirtd for image store \033[0m"
cd /var/lib/libvirt/images/
mkdir /home/images
systemctl start libvirtd
systemctl enable libvirtd
chcon -t virt_image_t /home/images/
cd /home/images/
systemctl start libvirtd
systemctl enable libvirtd



echo -e "\033[1;36mUndercloud Infra Creation\033[0m"


if ! ls -al CentOS-Stream-GenericCloud-8-20220125.1.x86_64.qcow2 ; then
      echo "Downloading RHEL-Server 7.6 Image" ; \
      curl -O https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20220125.1.x86_64.qcow2
 else 
      echo "Server Image already exist."
fi


qemu-img create -f qcow2 centos-8-guest.qcow2 100G
virt-resize --expand /dev/sda1 CentOS-Stream-GenericCloud-8-20220125.1.x86_64.qcow2 centos-8-guest.qcow2

# curl -O http://192.168.122.1:9090/CentOS-Stream-GenericCloud-8-20220125.1.x86_64.qcow2
qemu-img create -f qcow2 -b centos-8-guest.qcow2 undercloud.qcow2

virt-install \
--ram 18000 \
--vcpus 4 \
--os-variant virtio26 \
--disk path=/openstack/images/undercloud.qcow2,device=disk,bus=virtio,format=qcow2 \
--import \
--noautoconsole \
--vnc \
--network bridge=provibr1,model=virtio \
--network network:default \
--name undercloud



echo -e "\033[1;36mSpawning OverCloud Infra $ctrl ** Controllers **\033[0m"

user=$(id | awk '{print $1}' | sed 's/.*(//;s/)$//')
i=0
j=0
for img in `seq 1 $ctrl`; do qemu-img create -f qcow2 -o preallocation=metadata $user-ctrl-$((j++)).qcow2 60G ; done
i=0
j=0

cmd_ctrl() {
sudo virt-install --name $user-ctrl-$((i++))  --memory $mem_ctrl --vcpus 6 \
--disk /openstack/images/$user-ctrl-$((j++)).qcow2,bus=sata \
--import \
--os-variant ubuntu20.04 \
--network bridge=provibr1,model=virtio \
--network bridge=vlanbr2,model=virtio \
--network network:default \
--graphics=none \
--noautoconsole
}
for a in `seq 1 $ctrl`; do cmd_ctrl ; done



echo -e "\033[1;36mSpawning OverCloud Infra $cmpt ** Computes **\033[0m"

user=$(id | awk '{print $1}' | sed 's/.*(//;s/)$//')
i=0
j=0
for img in `seq 1 $cmpt`; do qemu-img create -f qcow2 -o preallocation=metadata $user-cmpt-$((j++)).qcow2 60G ; done
i=0
j=0

cmd_cmpt() {
sudo virt-install --name $user-cmpt-$((i++))  --memory $mem_cmpt --vcpus 6 \
--disk /openstack/images/$user-cmpt-$((j++)).qcow2,bus=sata \
--import \
--os-variant ubuntu20.04 \
--network bridge=provibr1,model=virtio \
--network bridge=vlanbr2,model=virtio \
--network network:default \
--graphics=none \
--noautoconsole
}

for a in `seq 1 $cmpt`; do cmd_cmpt ; done


echo -e "\033[1;36mStop Domains\033[0m"
for i in $(virsh list --all | grep -i $user | awk {'print $2'}); do virsh destroy $i ; done 


echo -e "\033[1;36mGet DOMAIN details\033[0m"

user=$(id | awk '{print $1}' | sed 's/.*(//;s/)$//')
for domain in $(sudo virsh list --all | grep -i $user | awk {'print $2'}) ;  \
do echo $domain; \
done > /openstack/images/txtfiles/domain.txt


echo -e "\033[1;36mAdd VBMC\033[0m"

i=6230
for j in $(cat /openstack/images/txtfiles/domain.txt) ; \
do vbmc add $j --port $((i++)) --username admin --password redhat ; vbmc start $j ; \
done > /openstack/images/txtfiles/vbmcport.txt
cat /openstack/images/txtfiles/vbmcport.txt



echo -e "\033[1;36mCheck Undercloud\033[0m"

UNDERCLOUD_IP=$(virsh domifaddr undercloud | awk {'print $4'}| awk 'NR>2'|  cut -d'/' -f1)
echo $UNDERCLOUD_IP
ping -c 5 $UNDERCLOUD_IP


clear


echo  -e "\033[42;5m Step_5: Infrastructure Setup Completed.  \033[0m"
user=$(id | awk '{print $1}' | sed 's/.*(//;s/)$//')
UNDERCLOUD_IP=$(virsh domifaddr undercloud | awk {'print $4'}| awk 'NR>2'|  cut -d'/' -f1)
echo "ssh $user@$UNDERCLOUD_IP"


for i in $(virsh list --all| egrep -v under | awk {'print $2'} | awk 'NR>2'); do echo $i ;  virsh domiflist $i | egrep -i brbm | awk {'print $5'} ; done > 1.txt ; sed 'N;s/\n/ /'  1.txt > 2.txt ; awk '{printf "%-30s|%-18s|%-20s\n",$1,$2,$3}' 2.txt > 3.txt ; clear ; cat 3.txt






