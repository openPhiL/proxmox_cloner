#! /bin/bash


# parameters:
# Target connection: 
SpareProxmox="root@10.0.2.11"
local_hostname=$(hostname)
remote_hostname="pve1"

# reading all container
for file in /etc/pve/nodes/$local_hostname/lxc/*
do
   if [[ $file =~ .*\lxc\/(.*).conf ]]
    then
      container+=(${BASH_REMATCH[1]})
    else
     echo "$date failed tp read lxc folder for container"
     exit
   fi
done

#reading all VMs
for file in /etc/pve/nodes/$local_hostname/qemu-server/*
do
   if [[ $file =~ .*\server\/(.*).conf ]]
    then
      vms+=(${BASH_REMATCH[1]})
    else
     echo "$date failed tp read qemu-server folder for vm's"
     exit
   fi
done

# processing each container
for i in "${container[@]}"
do
    echo "---- processing container $i ----------"
    
    snap_local=$(/usr/sbin/zfs get written |grep subvol-$i |grep daily | tail -1 | awk '{print $1}')
    echo "latest local snapshot: $snap_local"
    snap_remote=$(/usr/bin/ssh $SpareProxmox zfs get written |grep subvol-$i |grep daily | tail -1 | awk '{print $1}')
    echo "latest remote snapshot: $snap_remote"

    if [[ $snap_remote == "" ]]
    then       
        echo "$i needs to be created first - sending all snapshots"
        zfs send -R $snap_local | ssh $SpareProxmox zfs recv -dvF rpool

        echo "creating the config file /etc/pve/nodes/$local_hostname/lxc/$i.conf"
        scp /etc/pve/nodes/$local_hostname/lxc/$i.conf $SpareProxmox:/etc/pve/nodes/$remote_hostname/lxc/$i.conf

    else

        if [[ $snap_remote == $snap_local ]]
        then
            echo "$i skipping - is up-to-date!"
        else
            echo "$i needs updating:"
            container_is_running_on_remote=$(/usr/bin/ssh $SpareProxmox /usr/sbin/pct status $i)
            if [[ $container_is_running_on_remote == "status: stopped" ]]
            then
                snapid_remote=$(echo "$snap_remote" | awk -F @ '{ print $2 }')

                echo "most recent snap on remote: $snapid_remote"
                zfs send -I $snapid_remote -R $snap_local | ssh $SpareProxmox zfs recv -dvF rpool

                echo "updating the config file /etc/pve/nodes/$local_hostname/lxc/$i.conf"
                scp /etc/pve/nodes/$local_hostname/lxc/$i.conf $SpareProxmox:/etc/pve/nodes/$remote_hostname/lxc/$i.conf
            else 
                echo "spare is active, skip transfer/override"
            fi
        fi
    fi
done

#processing each vm
for i in "${vms[@]}"
do
    echo "---- processing VM $i ----------"

    snap_local=$(/usr/sbin/zfs get written |grep vm-$i |grep daily | tail -1 | awk '{print $1}')
    echo "latest local snapshot: $snap_local"
    snap_remote=$(/usr/bin/ssh $SpareProxmox zfs get written |grep vm-$i |grep daily | tail -1 | awk '{print $1}')
    echo "latest remote snapshot: $snap_remote"


    if [[ $snap_remote == "" ]]
    then

        echo "$i needs to be created first - sending all snapshots"
        zfs send -R $snap_local | ssh $SpareProxmox zfs recv -dvF rpool

        echo "creating the config file /etc/pve/nodes/$local_hostname/qemu-server/$i.conf"
        scp /etc/pve/nodes/$local_hostname/qemu-server/$i.conf $SpareProxmox:/etc/pve/nodes/$remote_hostname/qemu-server/$i.conf

    else

        if [[ $snap_remote == $snap_local ]]
        then
            echo "$i skipping - is up-to-date!"
        else
            echo "$i needs updating:"

            vm_is_running_on_remote=$(/usr/bin/ssh $SpareProxmox /usr/sbin/qm status $i)
            if [[ $vm_is_running_on_remote == "status: stopped" ]] 
            then
                snapid_remote=$(echo "$snap_remote" | awk -F @ '{ print $2 }')

                echo "most recent snap on remote: $snapid_remote"
                zfs send -I $snapid_remote -R $snap_local | ssh $SpareProxmox zfs recv -dvF rpool
                
                echo "updating the config file /etc/pve/nodes/$local_hostname/qemu-server/$i.conf"
                scp /etc/pve/nodes/$local_hostname/qemu-server/$i.conf $SpareProxmox:/etc/pve/nodes/$remote_hostname/qemu-server/$i.conf

            else 
                echo "spare is active, skip transfer/override"
            fi
        fi
    fi
done