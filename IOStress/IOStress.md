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
        9           mcracpoc1-ssd-p30x2       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        10          mcracpoc1-ssd-p30x3       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        11          mcracpoc1-ssd-p30x4       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        12          mcracpoc1-ssd-p30x5       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        13          mcracpoc1-ssd-p30x6       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        14          mcracpoc1-ssd-p30x7       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        15          mcracpoc1-ssd-p30x8       1024 GiB     Premium SSD  -> P60S        Not enabled       Read-only
        ----------------------------------------------------------------------------------------------------------
    
    ASM DG:
        ---------------------------------------------------------------------------------------------------------
        GroupName  Status  Mounted   Type    TotalMiB  FreeMiB   OfflineDisks  LostDisks  Resync  ReadLocal  Vote
        ---------------------------------------------------------------------------------------------------------
        DATA       Good    AllNodes  NORMAL  2097152   318848    0             0          No      Enabled    None
        FRA        Good    AllNodes  NORMAL  3145728   2816960   0             0          No      Enabled    None
        GRID       Good    AllNodes  NORMAL  10240     9336      0             0          No      Enabled    3/3 
        P60        Good    AllNodes  NORMAL  16777216  12398088  0             0          No      Enabled    None
        P60S       Good    AllNodes  NORMAL  16777216  12398008  0             0          No      Enabled    None
        P80        Good    AllNodes  NORMAL  67106816  62727408  0             0          No      Enabled    None
        ---------------------------------------------------------------------------------------------------------
    
    **NOTE:**
        - Azure only enable Read-Only disk cache for disk less than 4TB, which is P50.
        - FlashGrid only support Read-Only Caching Data disk. There is previous an issue when using none caching
        - FlashGrid reported OS issue when using NONE Caching disk for large IOPS. Need to verify status now.

  
**Create Oracle DB**

    Create IO Stress DB on each DG uisng DBCA and adjust TableSpace for slob test.
    
        -----------------------------------------------------------------------------------------------------------
        DBName      Block   TabaleSpace         DG          BIGFILE     SYSTEM      SYSAUX      FRA DG      REDO
        -----------------------------------------------------------------------------------------------------------
        P30DB       8KB     IOPS                DATA         800GiB     24GiB       24GiB       256GiB      10GiB*4(DATA)
        P60DB       8KB     IOPS                P60         2048GiB     24GiB       24GiB       256GiB      10GiB*4(P60)
        P80DB       8KB     IOPS                P80         2048GiB     24GiB       24GiB       256GiB      10GiB*4(P80)
        P60SDB      8KB     IOPS                P60S        2048GiB     24GiB       24GiB       256GiB      10GiB*4(P60S)
        -----------------------------------------------------------------------------------------------------------



    **NOTE: **
        - Resize SYSTEM/SYSAUX to prevent SLOB load failure. Authough it set to AUTO EXTEND, table space still used up like below example. 
  
            TABLESPACE_NAME    AUT    MAX_TS_SIZE    CURR_TS_SIZE    USED_TS_SIZE    TS_PCT_USED    FREE_TS_SIZE    TS_PCT_FREE
            ---------------    ---    -----------    ------------    ------------    -----------    ------------    ------------
            SYSTEM             YES    32767.98       920             912.06          99.14          7.94            1
            SYSAUX             YES    32767.98       630             603             95.71          27              4

        - Set REDO logs to a dedicate Disk Group to avoid any IO impact on Database DG. 
        - For M series, Accelerate Writer is suggested to enable on REDO log disk, not DB data disk. 


 **SLOB Test**

    1. Disable Read-Only Cache on all the disks. 
    2. Identify stress testing parameter by tuning schema, thread/schema and work_unit. monitor IOPS and Queue Length with IOSTAT

**AWR report**

    For each individual AWR report, saved in IOStress folder. Name conversion as following: 

        awr_p30x2_d8s_s64_t1_wu64
        |   |     |   |   |  |--------------Work Unit - 64
        |   |     |   |   |-----------------1 thread per schema
        |   |     |   |---------------------load 64 Schema
        |   |     |-------------------------VM Size - D8s
        |   |-------------------------------2 P30 disk in DG
        |-----------------------------------AWR Report Tag     

**Conclusion**

    1. FlashGrid SkyCluster is able to provide a RAC environment on cloud with high IO throughput.
   
    2. We can put the Premium Data Disk IOPS to its limitation without impact Oracle OS Stability
   
    3. Disk with READ-ONLY CACHE is helpful to improve the IO performance. Be careful to choose the Disk & VM size. 
   
    4. Use disks under 4T can be a good option if it can provide enough capacity.

