**Original Deployment:**

    OS Size:

        --------------------------------------------------------------------------------------------------------
        Name             Size        
        --------------------------------------------------------------------------------------------------------
        mcracpoc1        Standard D8s v3 (8 vcpus, 32 GiB memory)
        mcracpoc2        Standard D8s v3 (8 vcpus, 32 GiB memory)
        mcracpocq        Standard DS2 v2 (2 vcpus, 7 GiB memory)
        --------------------------------------------------------------------------------------------------------

    OS disk
        --------------------------------------------------------------------------------------------------------
        Name                Size        Storage account type        Encryption        Host caching
        --------------------------------------------------------------------------------------------------------
        mcracpoc1           32 GiB      Premium SSD                 Not enabled       Read-only
        mcracpoc2           32 GiB      Premium SSD                 Not enabled       Read-only
        mcracpocq           32 GiB      Premium SSD                 Not enabled       Read-only
        --------------------------------------------------------------------------------------------------------

    Data disks for DB Node
        --------------------------------------------------------------------------------------------------------
        LUN         Name                      Size        Storage account type        Encryption        Host caching
        --------------------------------------------------------------------------------------------------------
        0           disks_mcracpoc1_lun0_xxx  107 GiB     Premium SSD                 Not enabled       Read-only
        1           disks_mcracpoc1_lun1_xxx  5 GiB       Premium SSD                 Not enabled       Read-only
        2           disks_mcracpoc1_lun2_xxx  1024 GiB    Premium SSD                 Not enabled       Read-only
        3           disks_mcracpoc1_lun3_xxx  1024 GiB    Premium SSD                 Not enabled       Read-only
        5           disks_mcracpoc1_lun5_xxx  512 GiB     Premium SSD                 Not enabled       Read-only
        6           disks_mcracpoc1_lun6_xxx  512 GiB     Premium SSD                 Not enabled       Read-only
        7           disks_mcracpoc1_lun7_xxx  512 GiB     Premium SSD                 Not enabled       Read-only
        --------------------------------------------------------------------------------------------------------
    
    SkyCluster Layout
        --------------------------------------------------------------------------------------------------------
        GroupName  Status  Mounted   Type    TotalMiB  FreeMiB  OfflineDisks  LostDisks  Resync  ReadLocal  Vote
        --------------------------------------------------------------------------------------------------------
        DATA       Good    AllNodes  NORMAL  6291456   6291072  0             0          No      Enabled    None
        FRA        Good    AllNodes  NORMAL  3145728   3145344  0             0          No      Enabled    None
        GRID       Good    AllNodes  NORMAL  10240     9496     0             0          No      Enabled    3/3 
        --------------------------------------------------------------------------------------------------------

**Modifed Disk Config**

    Change Disk layout based on this consideration: 

        - Azure only enable Read-Only disk cache for disk less than 4TB, which is P50.
         - FlashGrid suggest to use Read-Only host cashing for data disk. There is previous an issue when using none caching, VM OS disk performance impected. Not sure if it is still the case, but follow this suggestion as for PoC. 
         - Test P60*1 DG(None Host Caching) vs P30*8 DG (Read-Only Host Caching).
  
    Data disks for DB Node
        --------------------------------------------------------------------------------------------------------
        LUN         Name                      Size         Storage account type        Encryption        Host caching
        --------------------------------------------------------------------------------------------------------
        0           disks_mcracpoc1_lun0_xxx  107 GiB      Premium SSD                 Not enabled       Read-only
        1           disks_mcracpoc1_lun1_xxx  5 GiB        Premium SSD                 Not enabled       Read-only
        2           disks_mcracpoc1_lun2_xxx  1024 GiB     Premium SSD  -> P30         Not enabled       Read-only
        3           mcracpoc1-ssd-p60         8192 GiB     Premium SSD  -> P60         Not enabled       None
        3           mcracpoc1-ssd-p80         32767 GiB    Premium SSD  -> P80         Not enabled       None
        5           disks_mcracpoc1_lun5_xxx  512 GiB      Premium SSD                 Not enabled       Read-only
        6           disks_mcracpoc1_lun6_xxx  512 GiB      Premium SSD                 Not enabled       Read-only
        7           disks_mcracpoc1_lun7_xxx  512 GiB      Premium SSD                 Not enabled       Read-only
        8           mcracpoc1-ssd-p30x1       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        9           mcracpoc1-ssd-p60x2       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        10          mcracpoc1-ssd-p60x3       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        11          mcracpoc1-ssd-p60x4       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        12          mcracpoc1-ssd-p60x5       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        13          mcracpoc1-ssd-p60x6       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        14          mcracpoc1-ssd-p60x7       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        15          mcracpoc1-ssd-p60x8       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        ----------------------------------------------------------------------------------------------------------
    
    SkyCluster Layout
        -----------------------------------------------------------------------------------------------------------
        GroupName  Status   Mounted    Type    TotalMiB  FreeMiB   OfflineDisks  LostDisks  Resync  ReadLocal  Vote
        -----------------------------------------------------------------------------------------------------------
        DATA       Good     AllNodes   NORMAL  2097152   2096792   0             0          No      Enabled    None
        FRA        Good     AllNodes   NORMAL  3145728   3145320   0             0          No      Enabled    None
        GRID       Good     AllNodes   NORMAL  10240     9336      0             0          No      Enabled    3/3 
        P60        Warning  SomeNodes  NORMAL  16777216  16776888  0             0          No      Enabled    None
        P80        Warning  SomeNodes  NORMAL  67106816  67106032  0             0          No      Enabled    None
        -----------------------------------------------------------------------------------------------------------

**Create Oracle DB**

    Create IO Stress DB on each DG
    https://docs.oracle.com/en/database/oracle/oracle-database/19/ostmg/create-db-asm-sqlplus.html#GUID-41FA8A5D-70D4-4CE7-A1A2-00220DE9B8F8

        -----------------------------------------------------------------------------------------------------------
        DBName      TabaleSpace         DG  
        -----------------------------------------------------------------------------------------------------------
        P30DB       P30TS               P30
        P60DB       P60TS               P60
        P80DB       P60TS               P80
        P60SDB      P60STS              P60S
        -----------------------------------------------------------------------------------------------------------

    Data disks throughput
        --------------------------------------------------------------------------------------------------------
        SKU     Disk size in GiB        IOPS per disk       Throughput per disk (MiB/sec)
        --------------------------------------------------------------------------------------------------------
        P30      1,024                   5,000              200
        P60      8,192                  16,000              500
        P80     32,767                  20,000              900
        --------------------------------------------------------------------------------------------------------

**IO Stress Test**

    1. Pre-Create 4 slob.conf file, each for one DB: p30DB_slob.conf, P60DB_slob.conf, P80DB_slob.conf, P60SDB_slob.conf. While scale the VM size, the slob configuration file is the same. DBs have been set to manual to prevent after start after boot.
   
        srvctl modify database -db p30db -policy MANUAL
        srvctl stop database -db p30db

    2. Cold boot all the node to ensure the environment is clean, check FlashGrid cluster status and ASM DG status.

        flashgrid-cluster
        flashgrid-dg

    3. After boot, there should be no DB instance running. Only start the DB for current load testing. 

        srvctl status database -thishome
        srvctl start database -db p30db
        srvctl status database -db p30db

    4. Seperated SLOB folder (slob-p30db, slob-p60db, slob-p60sdb, slob-p80db) are created accroding to each Database under /u01/slob. go to corresponding folder to do IO test. 
   

SCAN_PCT

|                      |  slob-p30db         |  slob-p60db       |  slob-p60sdb      |  slob-p80db       |   
|  ----                |  ----               |  ----             |  ----             |  ----             | 
| Scale size           |  100000 (800MB)     |  100000 (800MB)   |  100000 (800MB)   |  100000 (800MB)   |
| multi schema         |  20                 |  20               |  20               |  20               |
| HOT schema           |  TRUE               |  TRUE             |  TRUE             |  TRUE             |
| HOT Spot             |  FALSE              |  FALSE            |  FALSE            |  FALSE            |
| THREADS_PER_SCHEMA   |  5                  |  5                |  5                |  5                |
| UPDATE_PCT           |  15                 |  15               |  15               |  15               |
| RUN_TIME             |  300                |  300              |  300              |  300              |  
| WORK_UNIT            |  64                 |  64               |  64               |  64               |


