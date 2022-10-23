# Proxmox Cloner

This is a backup tool for a proxmox environment with a main proxmox server and a second (spare) proxmox system that acts as a place for the backup as well as a spare system to run them. (e.g. the main host catches fire).

set parameter in both files and then launch the cannon.

Requirement: [zfs-auto-snapshot](https://github.com/zfsonlinux/zfs-auto-snapshot) is installed on the main server that creates those snapshots. In default configuration, the dailys are grabbed.
