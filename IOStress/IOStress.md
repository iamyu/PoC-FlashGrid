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

 **IO Stress Test**

    |                      |  slob-p30db         |  slob-p60db       |  slob-p60sdb      |  slob-p80db       |   
    |  ----                |  ----               |  ----             |  ----             |  ----             | 
    | Scale size           |  8GB                |  8GB              |  8GB              |  8GB              |
    | Schema               |  64                 |  128              |  128              |  128              |
    | HOT_SCHEMA_FREQUENCY |  0                  |  0                |  0                |  0                |
    | DO_HOTSPOT           |  FALSE              |  FALSE            |  FALSE            |  FALSE            |
    | RUN_TIME             |  600                |  600              |  600              |  600              |  


        **NOTE:**
          - Cool boot Oracle RAC to start only one DB at one time for testing
          - For each VM size, test twice for SGA set to MIN and MAX


    1. There should be no DB instance running. Only start the DB for current load testing. 

        srvctl status database -thishome
        srvctl start database -db p30db
        srvctl status database -db p30db

        cat /u01/app/oracle/product/19.3.0/dbhome_1/network/admin/tnsnames.ora
        tnsping p30db

    2. Resize System & SysAux table space (10GiB). Default size full when doing some operation. suspect it will cause perf issues on DB. 



        one example for tablespace usage when loading SLOB schema without resize SYSTEM and SysAUX

        TABLESPACE_NAME 	   AUT      MAX_TS_SIZE MAX_TS_PCT_USED CURR_TS_SIZE USED_TS_SIZE TS_PCT_USED FREE_TS_SIZE TS_PCT_FREE
        ------------------------------ --- ----------- --------------- ------------ ------------ ----------- ------------ -----------
        SYSTEM			       YES    32767.98		  2.78		        920	        912.06          99.14	     7.94	    1
        SYSAUX			       YES    32767.98		  1.84		        630	        603             95.71	       27	    4
        IOPS			       YES    33554432		   .62	            217728      207306.19       95.21	 10421.81	    5
        UNDOTBS1		       YES    32767.98		   .09		        345	        28.25	        8.19	   316.75	   92
        UNDOTBS2		       YES    32767.98		   .08		        75	        26.56           35.42	    48.44	   65
        USERS			       YES    32767.98		   .01		        5	        2.69            53.75	     2.31	   46
        TEMP			       YES    32767.98		     0	            7529	    0	            0	        7529	  100


    3. SLOB environment configuration. Seperated SLOB folder (slob-p30db, slob-p60db, slob-p60sdb, slob-p80db) are created accroding to each Database under /home/oracle. Go to corresponding folder to do IO test. 

        sh ~/slob-p30db/setup.sh IOPS 64

            NOTIFY  : 2020.02.06-14:56:47 : Row and block counts for SLOB table(s) reported in ./slob_data_load_summary.txt
            NOTIFY  : 2020.02.06-14:56:47 : Please examine ./slob_data_load_summary.txt for any possbile errors
            NOTIFY  : 2020.02.06-14:56:47 : 
            NOTIFY  : 2020.02.06-14:56:47 : NOTE: No errors detected but if ./slob_data_load_summary.txt shows errors then
            NOTIFY  : 2020.02.06-14:56:47 : examine /home/oracle/slob-p30db/cr_tab_and_load.out

            NOTIFY  : 2020.02.06-14:56:47 : SLOB setup complete. Total setup time:  (16185 seconds)



        sh ~/slob-p60db/setup.sh IOPS 128
        
        sh ~/slob-p60sdb/setup.sh IOPS 128

        sh ~/slob-p80db/setup.sh IOPS 128
        
    4. 




    5. Set SGA to 80% to increase cache hit and reduce physical read IO.
    6.  
    7.  Set SGA to 5% to test physical IO with both Read & Write

   

**RESULT**

    Data Disks MATRIX
        --------------------------------------------------------------------------------------------------------
        SKU     Disk size in GiB        IOPS per disk       Throughput          Latency
        --------------------------------------------------------------------------------------------------------
        P30      1,024                   5,000              200                 
        P60      8,192                  16,000              500
        P80     32,767                  20,000              900
        --------------------------------------------------------------------------------------------------------




- Test P60*2 DG(None Host Caching) vs P30*16 DG (Read-Only Host Caching).