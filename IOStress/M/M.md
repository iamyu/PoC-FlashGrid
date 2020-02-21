Seperate the M series test as only this VM support Accelerate Write. Test same workload with Accelerate Write on REDO DG (FRA) enabled/disabled.

Mainly test the system with these Disk Layout: 

    ---------------------------------------------------------------------------------------------------------
    GroupName  Status  Mounted   Type    TotalMiB  FreeMiB   OfflineDisks  LostDisks  Resync  ReadLocal  Vote
    ---------------------------------------------------------------------------------------------------------
    FRA        Good    AllNodes  NORMAL  3145728   2735592   0             0          No      Enabled    None
    GRID       Good    AllNodes  NORMAL  10240     9384      0             0          No      Enabled    3/3 
    P30S       Good    AllNodes  NORMAL  33554432  31299680  0             0          No      Enabled    None
    P60S       Good    AllNodes  NORMAL  67108864  64907736  0             0          No      Enabled    None
    P60SFRA    Good    AllNodes  NORMAL  2097152   1686272   0             0          No      Enabled    None
    ---------------------------------------------------------------------------------------------------------

- P30x16 Disks: It is the most common disk size with READ-ONLY Cache function. Sample environment from FlashGrid Deployment Guild
- P60x8  Disks: Disks used by a customer which need to perform onprem Oracle to Azure migration.

    DB NAME   DG Name     DG Disks      MAX IOPS        CAPACITY    PRICE/MONTH           SGA     HOST CACHING    SCALE    SCHEMAS
    --------  ---------   --------     -----------     --------    -------------------    ----    --------------  -----    ----------
    P30SDB    P30S        P30x16x2     5000x32=160K    1Tx32=32T   $122.88x32=3,932.16    8GB     READ-ONLY       256M      1024
    P60SDB    P60S        P60x4x2      16000x8=128K    8Tx8=64T    $860.16x8 =‭6,881.28‬    8GB     NONE            256M      1024

**Select VM Size**

    DB NODE     UNCHACHED IOPS/THROUGHPUT    CACHED&TEMP IOPS/THROUGHPUT/CACHE        Disks    VM BANDWIDTH      TEST FOR DB             
    --------    -------------------------    ----------------------------------       -----    -------------     ------------
    M64         40,000 / 1000MBps            80,000  / 800MBps  / 1228 GiB            64       16,000Mbps        P30S    
    M128-32ms*  80,000 / 2000MBps            250,000 / 1600MBps / 2456 GiB            64       32,000Mbps        P60S

    * Use M128-32 to reduce the core usage while keep storage capability due to quota limitation in the test subscription

**Challances**

    The bigest chanllance is to find th right SLOB parameters to push storage to its limit. Tried different parameter, Oracle RAC reports GC related wait event before storeage IOPS reaches expected value. As our focus in on storage performance, try to workaround GC impact by different slob parameters.

    SCHEMA    WORK_UNIT    UPDATE_PCT    THREAD     READ IOPS    WRITE IOPS
    -------   ---------    ----------    -------    ---------    -----------
    256       4            0             1          133,013.57	    54.49	
    256       4            1             1          126,588.36	 1,508.69
    256       4            3             1          120,973.79	 4,214.72
    256       4            5             1           76,004.42	 4,366.45	
    256       4            10            1           60,663.60	 6,672.73

    Based on the above result, use UPDATE_PCT=3 as the baseline. 

**Test Result**
### Test 1: Small DB Active dataset. 
    ---------------------------------------------------------------------------------------------------------------------------------------------------------
    awr_p30x32_m64_s256_t1_wu4_update3     CACHE         IOPS          P-Reads/sec    P-Writes/sec     
    ----------------------------------     ----------   ----------    -----------    -------------                   
    NODE1                                  READ-ONLY    62,331.48     60,262.82	    2,068.66           
    NODE2                                  READ-ONLY ‭   62,857.03‬     60,710.97	  2,146.06
    -----                                  ----------   ----------   -----------    -------------
    RAC                                                125,188.51    120,973.79	    4,214.72 

    RAC Top Wait Event            Waits       ------------------------------------   % of Total Waits  --------------------------------------------------
    ---------------------------   -----       <32us   <64us   <128us	<256us  <512us  <1ms    <2ms    <4ms    <8ms    <16ms   <32ms   <64ms   <128ms	
    DB file sequential read       39.8M                       0.0       4.2	    48.8	28.6	11.4	4.1	    0.8	    2.0	    0.1	    0.0     0.0

    ----

    awr_p30x32_m64_s256_t1_wu4_update3     CACHE                             IOPS          P-Reads/sec    P-Writes/sec     
    ----------------------------------     -----------------------------     ----------    -----------    -------------                   
    NODE1                                  READ-ONLY WRITE-ACCELERATE*       59,225.79      57,118.83      2,106.96	
    NODE2                                  READ-ONLY WRITE-ACCELERATE* ‭      48,336.42      46,559.26      1,777.16
    -----                                  -----------------------------     ----------   ------------    -------------
    RAC                                                                      ‭107,562.22‬   103,678.09      3,884.13

    RAC Top Wait Event            Waits       ------------------------------------   % of Total Waits  --------------------------------------------------
    ---------------------------   -----       <32us   <64us   <128us	<256us  <512us  <1ms    <2ms    <4ms    <8ms    <16ms   <32ms   <64ms   <128ms	
    DB file sequential read       33.8M                       2.2	    50.7	37.0	4.7	    1.0	    4.0	    0.4	    0.0	    0.0     0.0     0.0

    WRITE-ACCELERATE*: only enable this feature on REDO log ASM Disk Group.


### Test 2: P30S DB, Active Dataset (2T) >> 3GiB SGA. READ Percent=100%, Cache Hit <30%  

    awr_p30x32_m64_s256_t1_wu12_low_cache_hit   CACHE                             IOPS          P-Reads/sec    P-Writes/sec     
    -----------------------------------------   -----------------------------     ----------    -----------    -------------                   
    NODE1                                       READ-ONLY WRITE-ACCELERATE*       ‭28,341.05‬     27,435.75        905.30	    
    NODE2                                       READ-ONLY WRITE-ACCELERATE* ‭      38,636.48     37,247.21      1,389.27
    -----                                       -----------------------------     ----------   ------------    -------------
    RAC                                                                           66,977.53     64,682.96‬      2,294.57‬

    RAC Top Wait Event            Waits       ------------------------------------   % of Total Waits  --------------------------------------------------
    ---------------------------   -----       <32us   <64us   <128us	<256us  <512us  <1ms    <2ms    <4ms    <8ms    <16ms   <32ms   <64ms   <128ms	<256ms <512ms
    DB file sequential read       1.2M                        0.0       3.6	    18.8	3.9	    2.3	    29.4	4.0	    3.1	    3.1	    29.0	2.6	
    db file parallel read       209.5K                                  0.0     0.5	    1.1	    0.8	    3.5	    8.1	    5.2	    5.1	    17.4	23.4	13.2	21.7
    db file parallel write       47.7K         1.8	  4.7	  5.7	    10.4	15.2	16.2	13.2	10.1	5.5	    2.3	    5.1	    7.0	    1.3	    1.4	


### Test 3: P30S DB, Active Dataset (2T) >> 3GiB SGA. READ Percent=100%, Cache Hit <= 50%
    awr_p30x32_m128_s256_t2_wu12_medium_cache_hit    CACHE                             IOPS          P-Reads/sec    P-Writes/sec     
    ----------------------------------------------   -----------------------------     ----------    -----------    -------------                   
    NODE1                                            READ-ONLY WRITE-ACCELERATE*       ‭59,362.93     59,284.90	     78.03	    
    NODE2                                            READ-ONLY WRITE-ACCELERATE* ‭      17,878.98     17,860.10	     18.88
    -----                                            -----------------------------     ----------   ------------    -------------
    RAC                                                                      ‭          77241.91      77,145          96.91

    RAC Top Wait Event            Waits       ------------------------------------   % of Total Waits  --------------------------------------------------
    ---------------------------   -----       <32us   <64us   <128us	<256us  <512us  <1ms    <2ms    <4ms    <8ms    <16ms   <32ms   <64ms   <128ms	<256ms
    DB file sequential read          6M                       0.1	    6.0	    24.2	8.5	    4.8	    43.0	11.6	1.2	    0.2	    0.1	    0.2	    0.1	
    DB file sequential read*       3.4M                                         20.7	11.1	6.6	    44.1	15.0	1.7	    0.3	    0.5

    * The value is from the stress node.


### Test 4: P60S DB, NONE CACHE on Data Disk, READ-ONLY + Write Accelerate on REDO Log. SCALE = 512M, SCHEMA count = 1024.
    awr_p60x6_m128__s256_t2_wu80                  CACHE                             IOPS          P-Reads/sec    P-Writes/sec     
    -----------------------------------------   -----------------------------     ----------    -----------    -------------                   
    NODE1                                       READ-ONLY WRITE-ACCELERATE*       32,494.78‬     32,490.32      4.46	
    NODE2                                       READ-ONLY WRITE-ACCELERATE* ‭      47,211.66‬     47,207.37      4.29
    -----                                       -----------------------------     ----------   ------------    -------------
    RAC                                                                      ‭     79,706.44‬     79,697.69      8.75

    RAC Top Wait Event            Waits       ------------------------------------   % of Total Waits  --------------------------------------------------
    ---------------------------   -----       <32us   <64us   <128us	<256us  <512us  <1ms    <2ms    <4ms    <8ms    <16ms   <32ms   <64ms   <128ms	<256ms
    DB file sequential read       2.3M                                                          0.0     31.3    42.8    14.3    4.5     3.7     2.9     0.3

