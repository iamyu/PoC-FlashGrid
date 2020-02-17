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


| VM Size | Max_IOPS | DISK | IOPS | QTR | RAC_IOPS  | CACHE | IOPS_RESULT |DB_S_R_WAIT |<32us|<64us|<128us|<256us|<512us|<1ms|<2ms|<4ms|<8ms|<16ms|<32ms|<64ms|<128ms|
| ----    |----      |----  |----  |---- |----       | ----  | ----        |----        |---- |---- |----  |----  |----  |----|----|----|----|---- |---- |---- |----  |
| E32v3   | 51.2K/64K|P30   |  5K  |  2  |  10K      | NONE  |  8039       |  4.2M      |-    |-    |-     |-     |-     |-   |-   |73.1|20.9|2.8  |2.4  |0.8  |0.0   |
| E32v3   | 51.2K/64K|P30   |  5K  |  2  |  10K      | READ  |  9215       |  4.8M      |-    |-    |-     |0.3   |13.2  |3.7 |0.6 |64.5|12.9|1.9  |2.1  |0.9  |0.0   |
| E32v3   | 51.2K/64K|P30   |  5K  | 16  |  80K      | NONE  |   61K       |  6.2M      |-    |-    |-     |-     |-     |-   |-   |73.2|18.1|3.7  |3.8  |1.1  |0.0   |
| E32v3   | 51.2K/64K|P30   |  5K  | 16  |  80K      | READ  |   44K       |  4.4M      |-    |-    |-     |0.3   |8.8   |3.9 |1.5 |61.8|19.8|2.1  |1.4  |0.4  |0.0   |
| E32v3   | 51.2K/64K|P60   | 16K  |  2  |  32K      | NONE  |   25K       | 13.3M      |-    |-    |-     |-     |-     |-   |-   |90.1|4.9 |2.5  |2.2  |0.3  |0.0   |
| E32v3   | 51.2K/64K|P80   | 20K  |  2  |  40K      | NONE  |   33K       |  5.5M      |-    |-    |-     |-     |-     |-   |-   |60.5|23.4|4.5  |9.4  |2.2  |0.0   |
|         |          |      |      |     |           |       |             |            |     |     |      |      |      |    |    |    |    |     |     |     |      |
| M64     | 40K/80K  |P30   |  5K  | 32  | 160K      | READ  |   125K      | 39.8M      |-    |-    |-     |4.2   |48.8  |28.6|11.4|4.1 |0.8 |2.0  |0.1  |0.0  |0.0   |
| M64     | 40K/80K  |P30   |  5K  | 32  | 160K      | R-WA  |   107K      | 33.8M      |0.0  |0.0  | 2.2  |50.7  |37.0  |4.7 |1.0 |4.0 |0.4 |0.0  |0.0  |0.0  |0.0   |
| M128    | 80K/160K |P60   | 16K  |  8  | 128K      | NONE  |             |            |0.0  |0.0  | 0.0  |0.0   |0.0   |0.0 |0.0 |0.0 |0.0 |0.0  |0.0  |0.0  |0.0   |
| M128    | 80K/160K |P60   | 16K  |  8  | 128K      | N-WA  |             |            |0.0  |0.0  | 0.0  |0.0   |0.0   |0.0 |0.0 |0.0 |0.0 |0.0  |0.0  |0.0  |0.0   |

    awr_p60x2_e32s_s128_t1_wu4      Caching     IOPS        P-Reads/sec    P-Writes/sec     
    ---------------------------     ---------   --------    -----------    -------------                   
    NODE1                           NONE        12,096      10,470.65	    1,625.94	                     	                   
    NODE2                           NONE        13,009      11,226.43	    1,782.84	                                      	
    
    RAC                             Waits       ------------------------------------   % of Total Waits  --------------------------------------------------
    ---------------------------     -----       <32us   <64us   <128us	<256us  <512us  <1ms    <2ms    <4ms    <8ms    <16ms   <32ms   <64ms   <128ms	
    DB file sequential read         13.3M         	 	 	 	 	 	                        0.0     90.1	4.9	    2.5	    2.2	    0.3	    0.0
    DB db file parallel write       152.1K       0.5	4.1	    4.1	    9.4	    11.9    17.8	22.6    19.2	5.4	    3.0	    1.8	    0.2	    0.0


1. FlashGrid SkyCluster is able to provide a RAC environment on cloud with high IO throughput.
2. We can put the Premium Data Disk IOPS to its limitation without impact Oracle OS Stability
3. Disk with READ-ONLY CACHE is helpful to improve the IO performance. Be careful to choose the Disk & VM size.
4. Use disks under 4T can be a good option if it can provide enough capacity. 
5. As VM Cached IO throughput limitation is much higher than the none cached limit, by choosing P-SSD smaller than 4T, we can also choose a small VM size to support high Cached IO throughput. 

