Seperate the M series VM test as only this VM support Accelerate Write. Enable Accelerate Write on REDO DG (FRA) and perform IO TEST for all the Database. 

Mainly test the system with these Disk Layout: 

- P30x16 Disks: It is the most common disk size with READ-ONLY Cache function. Sample environment from FlashGrid Deployment Guild
- P60x8  Disks: Disks used by a customer which need to perform onprem Oracle to Azure migration.

    DB NAME      ASM DG      MAX IOPS        CAPACITY    PRICE/MONTH            SGA     HOST CACHING    SCALE    SCHEMAS
    --------     -------     -----------     --------    -------------------    ----    --------------  -----    ----------
    P30SDB       P30x16x2    5000x32=160K    1Tx32=32T   $122.88x32=3,932.16    8GB     READ-ONLY       256M     512/NODE
    P60SDB       P60x4x2     16000x8=128K    8Tx8=64T    $860.16x8 =‭6,881.28‬    8GB     NONE            256M     512/NODE

**Select VM Size**

    DB NODE    UNCHACHED IOPS/THROUGHPUT    CACHED&TEMP IOPS/THROUGHPUT/CACHE        Disks    VM BANDWIDTH      TEST FOR DB             
    --------   -------------------------    ----------------------------------       -----    -------------     ------------
    M64        40,000 / 1000MBps            80,000  / 800MBps  / 1228 GiB            64       16,000Mbps        P30S    
    M128       80,000 / 2000MBps            250,000 / 1600MBps / 2456 GiB            64       32,000Mbps        P60S

**Test Result**

    awr_p30x32_m64_s***_t1_wu**     IOPS        P-Reads/sec    P-Writes/sec     
    ---------------------------     --------    -----------    -------------                   
    NODE1                                     	                   
    NODE2                                
    
    RAC Top Wait Event            Waits       ------------------------------------   % of Total Waits  --------------------------------------------------
    ---------------------------   -----       <32us   <64us   <128us	<256us  <512us  <1ms    <2ms    <4ms    <8ms    <16ms   <32ms   <64ms   <128ms	
    DB file sequential read         
    db file parallel read           

    ----
    ----

    