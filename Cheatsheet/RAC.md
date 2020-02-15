# Environment is setup using FlashGrid SkyCluster. 

# Verify the status of flashgrid.

    [az-admin@mcracpoc1 ~]$ sudo flashgrid-cluster
    FlashGrid 19.6.125.61312 #b88c44413835d07ec73adbf88c218a28329fc401
    License: Active, Expires 2020-03-03
    Licensee: demo
    Support plan: Demo
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FlashGrid running: OK
    Clocks check: OK
    Configuration check: OK
    Network check: OK

    Querying nodes: mcracpoc1, mcracpoc2, mcracpocq ...

    Cluster Name: mcracpoc
    Cluster status: Good
    -----------------------------------------------------------------
    Node       Status  ASM_Node  Storage_Node  Quorum_Node  Failgroup
    -----------------------------------------------------------------
    mcracpoc1  Good    Yes       Yes           No           MCRACPOC1
    mcracpoc2  Good    Yes       Yes           No           MCRACPOC2
    mcracpocq  Good    No        No            Yes          MCRACPOCQ
    -----------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------
    GroupName  Status  Mounted   Type    TotalMiB  FreeMiB  OfflineDisks  LostDisks  Resync  ReadLocal  Vote
    --------------------------------------------------------------------------------------------------------
    DATA       Good    AllNodes  NORMAL  6291456   6291072  0             0          No      Enabled    None
    FRA        Good    AllNodes  NORMAL  3145728   3145344  0             0          No      Enabled    None
    GRID       Good    AllNodes  NORMAL  10240     9472     0             0          No      Enabled    3/3 
    --------------------------------------------------------------------------------------------------------

# Verify Disk Connection:

    sudo blkid -s UUID
    ls -l /dev/disk/azure/scsi1/
    cat /etc/fstab
    sudo lvdisplay && sudo  pvdisplay

    lrwxrwxrwx 1 root root 12 Feb  3 10:06 lun0 -> ../../../sdc         <-- /u01
    lrwxrwxrwx 1 root root 12 Feb  3 10:33 lun1 -> ../../../sdh         <-- GRID
    lrwxrwxrwx 1 root root 12 Feb  3 10:33 lun2 -> ../../../sde         <-- DATA
    lrwxrwxrwx 1 root root 12 Feb  3 10:33 lun3 -> ../../../sdi
    lrwxrwxrwx 1 root root 12 Feb  3 10:33 lun4 -> ../../../sdd
    lrwxrwxrwx 1 root root 12 Feb  3 10:33 lun5 -> ../../../sdg         <-- FRA
    lrwxrwxrwx 1 root root 12 Feb  3 10:33 lun6 -> ../../../sdf
    lrwxrwxrwx 1 root root 12 Feb  3 10:33 lun7 -> ../../../sdj

# ASM Management 

    sudo su - grid

    sqlplus / as sysasm

    column name format a15
    column DG# format 99
    select group_number DG#, name, state, type, total_mb, free_mb from v$asm_diskgroup;

    # remove disk from DG with sqlplus

    alter diskgroup DATA
    drop disk mcracpoc1$lun3
    drop disk mcracpoc1$lun4
    drop disk mcracpoc2$lun3
    drop disk mcracpoc2$lun4
    rebalance wait;

    # stop target on each local node
    sudo flashgrid-node stop-target /dev/flashgrid/mcracpoc1.lun3
    sudo flashgrid-node stop-target /dev/flashgrid/mcracpoc1.lun4
    sudo flashgrid-node stop-target /dev/flashgrid/mcracpoc2.lun3
    sudo flashgrid-node stop-target /dev/flashgrid/mcracpoc2.lun4

    # Deattach the disks from VM.

    # Create DiskGroup P60 and P80

    sudo flashgrid-dg create --name P60 --normal --asm-compat 19.0.0.0.0 --db-compat 19.0.0.0.0 --au-size 4M --disks /dev/flashgrid/mcracpoc1.lun3 /dev/flashgrid/mcracpoc2.lun3
    sudo flashgrid-dg create --name P80 --normal --asm-compat 19.0.0.0.0 --db-compat 19.0.0.0.0 --au-size 4M --disks /dev/flashgrid/mcracpoc1.lun4 /dev/flashgrid/mcracpoc2.lun4
    sudo flashgrid-dg create --name P60S --normal --asm-compat 19.0.0.0.0 --db-compat 19.0.0.0.0 --au-size 4M --disks /dev/flashgrid/mcracpoc1.lun8 /dev/flashgrid/mcracpoc1.lun9 /dev/flashgrid/mcracpoc1.lun10 /dev/flashgrid/mcracpoc1.lun11 /dev/flashgrid/mcracpoc1.lun12 /dev/flashgrid/mcracpoc1.lun13 /dev/flashgrid/mcracpoc1.lun14 /dev/flashgrid/mcracpoc1.lun15 /dev/flashgrid/mcracpoc2.lun8 /dev/flashgrid/mcracpoc2.lun9 /dev/flashgrid/mcracpoc2.lun10 /dev/flashgrid/mcracpoc2.lun11 /dev/flashgrid/mcracpoc2.lun12 /dev/flashgrid/mcracpoc2.lun13 /dev/flashgrid/mcracpoc2.lun14 /dev/flashgrid/mcracpoc2.lun15

# FlashGrid cluster Management

    # Shutdown entire cluster after stop all the DBs
    sudo /u01/app/19.3.0/grid/bin/crsctl stop cluster -all

# Check Disk IO

    iostat sdx -xmt 1   <-- better to monitor on specfic disk as there are a lot of disk connected. note the x ID may change after reboot.

