**Original Deployment:**

    OS Size:

        --------------------------------------------------------------------------------------------------------
        Name             Size         --------------------------------------------------------------------------------------------------------
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

        srvctl status database -thishome
        srvctl start database -db p30db
        sqlplus system/7xZfhC47nL3tB9rF@p30db
        ALTER TABLESPACE SYSTEM ADD DATAFILE '+DATA' SIZE 24G;
        ALTER TABLESPACE SYSAUX ADD DATAFILE '+DATA' SIZE 24G;
        CREATE BIGFILE TABLESPACE IOPS DATAFILE '+DATA' SIZE 768G AUTOEXTEND ON NEXT 8G MAXSIZE UNLIMITED;

    **NOTE: **
        - Resize SYSTEM/SYSAUX to prevent SLOB load failure. Authough it set to AUTO EXTEND, table space still used up like below example. 
  
              TABLESPACE_NAME 	   AUT      MAX_TS_SIZE MAX_TS_PCT_USED CURR_TS_SIZE USED_TS_SIZE TS_PCT_USED FREE_TS_SIZE TS_PCT_FREE
            ------------------------------ --- ----------- --------------- ------------ ------------ ----------- ------------ --------
            SYSTEM			       YES    32767.98		  2.78		        920	        912.06          99.14	     7.94	    1
            SYSAUX			       YES    32767.98		  1.84		        630	        603             95.71	       27	    4
            IOPS			       YES    33554432		   .62	            217728      207306.19       95.21	 10421.81	    5
            UNDOTBS1		       YES    32767.98		   .09		        345	        28.25	        8.19	   316.75	   92
            UNDOTBS2		       YES    32767.98		   .08		        75	        26.56           35.42	    48.44	   65
            USERS			       YES    32767.98		   .01		        5	        2.69            53.75	     2.31	   46
            TEMP			       YES    32767.98		     0	            7529	    0	            0	        7529	  100

        - Set REDO logs to using FRA Disk Group to avoid any IO impact on Database DG.


 **SLOB Test**

    1. Disable Read-Only Cache on all the disks. 
    2. Run Quick SLOB test to find out the right parameter to stree IO for P30, P60, P60S and P80.
    3. when scale VM, change the SGA size, otherwise, DB will wait for other event object, like buffer, instead of DB file read/write.
    
    
    Identify stress testing parameter by tuning schema, thread/schema and work_unit. monitor disk load with iostat for expected IOPS

    iostat -x sdc sdd sde sdf sdg sdch sdi sdj sdk sdl sdm sdn sdo sdp sdq sdr 10 20

**RESULT**

    Data Disks MATRIX
        --------------------------------------------------------------------------------------------------------
        SKU     Disk size in GiB        IOPS per disk       Throughput          Latency
        --------------------------------------------------------------------------------------------------------
        P30      1,024                   5,000              200                 
        P60      8,192                  16,000              500
        P80     32,767                  20,000              900
        --------------------------------------------------------------------------------------------------------

    For each individual AWR report, saved in IOStress folder. Name conversion as following: 

        awr_p30x2_d8s_s64_t1_wu64
        |   |     |   |   |  |--------------Work Unit - 64
        |   |     |   |   |-----------------1 thread per schema
        |   |     |   |---------------------load 64 Schema
        |   |     |-------------------------VM Size - D8s
        |   |-------------------------------2 P30 disk in DG
        |-----------------------------------AWR Report Tag     

**Conclusion**

1. Due to Host Read-Only Cache, the total Disk IOPS can exceed limit since the IO does not really goes to storage. 



2. 
