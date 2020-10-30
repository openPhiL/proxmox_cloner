#! /bin/bash

#------------------
# This script will copy the proxmox_cloner to the main server where it extracts the 
# config files and snapshots and pushes them to the target spare server.
#------------------
# Prerequisits: 
# - main must be able to access spare with ssh key
# - the system this script is running needs to be able to access the main with ssh key


# parameters:
# Target connection: 
MainProxmox="root@10.0.2.12"


## copy proxmox_cloner.sh and executes it
echo "copy cloner to main proxmox server"
/usr/bin/scp /usr/local/sbin/proxmox_cloner.sh $MainProxmox:/usr/local/sbin/proxmox_cloner.sh 

echo "make it executable"
/usr/bin/ssh $MainProxmox chmod +x /usr/local/sbin/proxmox_cloner.sh

echo "execute it"
/usr/bin/ssh $MainProxmox /usr/local/sbin/proxmox_cloner.sh


 