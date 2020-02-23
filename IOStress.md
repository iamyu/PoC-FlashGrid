# PoC environment:

    VM Size:
        --------------------------------------------------------------------------------------------------------      
        Name             Deployment 1               Deployment 2 
        --------------------------------------------------------------------------------------------------------  
        mcracpoc1        Standard D8s               Standard M64s 
        mcracpoc2        Standard D8s               Standard M64s 
        mcracpocq        Standard DS2               Standard M8*
        --------------------------------------------------------------------------------------------------------  
        * Manually move M8 quorum node to another availability set and resize to D4s for cost saving.

        --------------------------------------------------------------------------------------------------------
        Size     vCore    RAM    Ddata disks    Cached throughput    None-cached throughput    Network bandwidth
        --------------------------------------------------------------------------------------------------------
        D8s_v3	 8         32    16          16K/  128MBps/  200GiB      12800 / 192             4000Mbps
        E32_v3	 32       256    32          64K/  512MBps/  800GiB      51200 / 768             16000Mbps
        E64_v3	 64       432    32         128K/ 1024MBps/ 1600GiB      80000 / 1200            30000Mbps
        M64      64      1024    64          80K/  800MBps/ 1228GiB      40000 / 1000            16000Mbps
        M64s	 64      1024    64          80K/  800MBPS/ 6348GiB      40000 / 1000            16000Mbps
        M128	 128     2048    64         250K/ 1600MBPS/ 2456GiB      80000 / 2000            32000Mbps
        --------------------------------------------------------------------------------------------------------

    OS disk
        --------------------------------------------------------------------------------------------------------
        Name                Size        Storage account type        Encryption        Host caching
        --------------------------------------------------------------------------------------------------------
        mcracpoc1           32 GiB      Premium SSD                 Not enabled       Read-only
        mcracpoc2           32 GiB      Premium SSD                 Not enabled       Read-only
        mcracpocq           32 GiB      Premium SSD                 Not enabled       Read-only
        --------------------------------------------------------------------------------------------------------

    Deployment 1 ASM DG:
        ---------------------------------------------------------------------------------------------------------
        GroupName  Status  Mounted   Type    TotalMiB  FreeMiB   ReadLocal  Vote    Disks
        ---------------------------------------------------------------------------------------------------------
        DATA       Good    AllNodes  NORMAL  2097152   318848    Enabled    None    P30 x 1 x 2 nodes
        FRA        Good    AllNodes  NORMAL  3145728   2816960   Enabled    None    P20 x 3 x 2 nodes
        GRID       Good    AllNodes  NORMAL  10240     9336      Enabled    3/3     P2  x 1 x 2 nodes
        P60        Good    AllNodes  NORMAL  16777216  12398088  Enabled    None    P60 x 1 x 2 nodes
        P60S       Good    AllNodes  NORMAL  16777216  12398008  Enabled    None    P30 x 8 x 2 nodes
        P80        Good    AllNodes  NORMAL  67106816  62727408  Enabled    None    P80 x 1 x 2 nodes
        ---------------------------------------------------------------------------------------------------------
    **NOTE:**
        - P60S means use P30 Disk to create same capacity as one P60 (striped)
        - P60 & P80 disks are added manually to ASM after cluster deployed. 
        - Use NONE cached disk is not recommended/supported by FlashGrid for the time being (Feb 2020)


    Deployment 2 ASM DG:
        ---------------------------------------------------------------------------------------------------------
        GroupName  Status  Mounted   Type    TotalMiB  FreeMiB   ReadLocal  Vote    Disks
        ---------------------------------------------------------------------------------------------------------
        FRA        Good    AllNodes  NORMAL  3145728   2735592   Enabled    None    P20 x 3  x 2 nodes
        GRID       Good    AllNodes  NORMAL  10240     9328      Enabled    3/3     P2  x 3  x 2 nodes
        P30S       Good    AllNodes  NORMAL  33554432  16603288  Enabled    None    P30 x 16 x 2 nodes
        P60S       Good    AllNodes  NORMAL  67108864  50162560  Enabled    None    P60 x 4  x 2 nodes
        P60SFRA    Good    AllNodes  NORMAL  2097152   1687104   Enabled    None    P30 x 1  x 2 nodes
        ---------------------------------------------------------------------------------------------------------

    **NOTE:**
        - Azure only enable Read-Only disk cache for disk less than 4TB. FlashGrid only support disks with READ-ONLY cache.
        - P30S & P60S here means multiple disks. 
  
# Oracle DB

    Deployment 1 Test DB:
        -----------------------------------------------------------------------------------------------------------
        DBName      Block   TabaleSpace         DG          BIGFILE     SYSTEM      SYSAUX      FRA DG      REDO
        -----------------------------------------------------------------------------------------------------------
        P30DB       8KB     IOPS                DATA         800GiB     24GiB       24GiB       256GiB      10GiB*4
        P60DB       8KB     IOPS                P60         2048GiB     24GiB       24GiB       256GiB      10GiB*4
        P80DB       8KB     IOPS                P80         2048GiB     24GiB       24GiB       256GiB      10GiB*4
        P60SDB      8KB     IOPS                P60S        2048GiB     24GiB       24GiB       256GiB      10GiB*4
        -----------------------------------------------------------------------------------------------------------
    
    Deployment 2 Test DB:
        -----------------------------------------------------------------------------------------------------------
        DBName      Block   TabaleSpace         DG          BIGFILE     SYSTEM      SYSAUX      FRA DG      REDO
        -----------------------------------------------------------------------------------------------------------
        P30SDB       8KB     IOPS                P30S       8192GiB     24GiB       24GiB       768GiB      50GiB*4
        P60SDB       8KB     IOPS                P60S       8192GiB     24GiB       24GiB       768GiB      50GiB*4
        -----------------------------------------------------------------------------------------------------------

    **NOTE: **
        - Resize SYSTEM/SYSAUX to 24GB. Authough it set to AUTO EXTEND, tablespace still used up which cause slob load failure.
        - Add additional temp file to TEMP tablespace. When loading large data volume, Default 32GiB temp file could be used up. 
        - Set REDO logs to a dedicate Disk Group (FRA) to avoid IO impact on Database DG. 
        - Locating REDO log in different DG is necessary as Write Accelerate suggested on REDO log only, not on DB file.
        - Create Bigfile Tablespace named IOPS. It takes hours to complete when the size reaches TB level. Sample for sizing 8TB tablespace.

![SLOB Load](ScreenShot/Oracle_TableSpace_8TB_P30_DiskIO.jpg)

# SLOB Test

    1. Restart RAC before test to clear SGA and HOST CACHE.
    2. Test P-SSD without cache enabled. Not a suggested comfiguration. just to understand the disk latency without cache. 
    3. None Cache IO test result is consistant with different VM size. Normal DB File sequencial read complete in 2-4ms.  
    4. Stress IO with different schema and work unit but keep thread number 1 to reduce parallel IO opertion contension. 
    5. Monitor the IO load with Azure Monitor Metrics and IOState.

    For each individual AWR report saved in IOStress folder, saved in IOStress folder. Name conversion as following.

        awr_p30x2_d8s_s64_t1_wu64
        |   |     |   |   |  |--------------Work Unit - 64
        |   |     |   |   |-----------------1 thread per schema
        |   |     |   |---------------------load 64 Schema
        |   |     |-------------------------VM Size - D8s
        |   |-------------------------------2 P30 disk in DG
        |-----------------------------------AWR Report Tag  

# Metrics

## Dployment 1: 
    
    - Test with Ds Es VMs. This round of test focus on single disk performance with small active set (100GB-500GB)
    - Use various SLOB parameter to stress IO to 80-90% utilization except marked with *. This is a smaple data for 50% utilization from comparasion.
    - With host READ-ONLY cache enabled, IO latency was improved but with limited level due to host cache size.

| VM Size | Max_IOPS | DISK | IOPS | QTR | RAC_IOPS  | CACHE | IOPS_RESULT |DB_S_R_WAIT |<32us|<64us|<128us|<256us|<512us|<1ms |<2ms |<4ms |<8ms |<16ms|<32ms|<64ms|<128ms|
| :---    |--------: |---:  |---:  |---: |--------:  | ---:  | ----------: |----------: |:--: |:--: |:--:  |:--:  |:--:  |:--: |:--: |:--: |:--: |:--: |:--: |:--: |:--:  |
| D8sv3   | 51K/64K  |P30   |  5K  |  2  |  10K      | NONE  |  8039       |  4.2M      |-    |-    |-     |-     |-     |-    |-    |73.1 |20.9 |2.8  |2.4  |0.8  |0.0   |
| E32v3   | 51K/64K  |P30   |  5K  |  2  |  10K      | READ  |  9215       |  4.8M      |-    |-    |-     |0.3   |13.2  |3.7  |0.6  |64.5 |12.9 |1.9  |2.1  |0.9  |0.0   |
| E32v3   | 51K/64K  |P30   |  5K  | 16  |  80K      | NONE  |   61K       |  6.2M      |-    |-    |-     |-     |-     |-    |-    |73.2 |18.1 |3.7  |3.8  |1.1  |0.0   |
| E32v3   | 51K/64K  |P30   |  5K  | 16  |  80K      | READ  |   44K*      |  4.4M      |-    |-    |-     |0.3   |8.8   |3.9  |1.5  |61.8 |19.8 |2.1  |1.4  |0.4  |0.0   |
| E32v3   | 51K/64K  |P60   | 16K  |  2  |  32K      | NONE  |   25K       | 13.3M      |-    |-    |-     |-     |-     |-    |-    |90.1 |4.9  |2.5  |2.2  |0.3  |0.0   |
| E32v3   | 51K/64K  |P80   | 20K  |  2  |  40K      | NONE  |   33K       |  5.5M      |-    |-    |-     |-     |-     |-    |-    |60.5 |23.4 |4.5  |9.4  |2.2  |0.0   |

## Deployment 2: 

    - M series VM test targets for large Data volume.
    - IOPS P30x32 is higher than P60x8. As P30 with READ-ONLY Cache. M64 is capable for P30 IO Testing but have to swtich to M128 for P60. 
    - Tested P30S DB without READ-ONLY cache and did not push to IOPS limitation. Over 90% DB file sequencial read completed in 2-4ms which is similar with Ds & Es. 
    - Write Accelerate enabeld on REDO log Disk Group, not on DB file Disk Group. 

### Test 1: P30S DB, Host Cache >> 65GiB Active Dataset > 3GiB SGA. Cache Hit (100%).

| VM Size | Max_IOPS | DISK | IOPS | QTR | RAC_IOPS  | CACHE | IOPS_RESULT |DB_S_R_WAIT |<32us|<64us|<128us|<256us|<512us|<1ms |<2ms |<4ms |<8ms |<16ms|<32ms|<64ms|<128ms|
| :---    |--------: |---:  |---:  |---: |--------:  | ---:  | ----------: |----------: |:--: |:--: |:--:  |:--:  |:--:  |:--: |:--: |:--: |:--: |:--: |:--: |:--: |:--:  |
| M64     | 40K/80K  |P30   |  5K  | 32  | 160K      | READ  |  125K       | 39.8M      |-    |-    |-     |4.2   |48.8  |28.6 |11.4 |4.1  |0.8  |2.0  |0.1  |0.0  |0.0   |
| M64     | 40K/80K  |P30   |  5K  | 32  | 160K      | R-WA  |  107K       | 33.8M      |-    |-    | 2.2  |50.7  |37.0  |4.7  |1.0  |4.0  |0.4  |0.0  |0.0  |0.0  |0.0   |

![Test 1](ScreenShot/SLOB_Stress_65GData_P30_DiskIO_5min.jpg?raw=true)

      - Azure VM Metrics indicate almost 100% READ Cache Hit rate. 
      - Over 50% completed less than 512us. less than 20% over 2ms.
      - Write Accelarate make it even better. 50% less than 256us, 95% completed in 1ms. 


### Test 2: P30S DB, Active Dataset (2T) >> 3GiB SGA. READ Percent=100%, Cache Hit <30%

| VM Size | Max_IOPS | DISK | IOPS | QTR | RAC_IOPS  | CACHE | IOPS_RESULT |DB_S_R_WAIT |<32us|<64us|<128us|<256us|<512us|<1ms |<2ms |<4ms |<8ms |<16ms|<32ms|<64ms|<128ms|
| :---    |--------: |---:  |---:  |---: |--------:  | ---:  | ----------: |----------: |:--: |:--: |:--:  |:--:  |:--:  |:--: |:--: |:--: |:--: |:--: |:--: |:--: |:--:  |
| M64     | 40K/80K  |P30   |  5K  | 32  | 160K      | R-WA  |    67K      |   1.2M     |-    |-    |-     |3.6   |18.8  |3.9  |2.3  |29.4 |4.0  |3.1  |3.1  |29.0 |2.6   |


    * M64 HOST CACHE: 1228GiB * 2 = 8GiB * 307 | M128 HOST CACHE: 2456 * 2 = 8GiB * 614

![Test 2](ScreenShot/SLOB_Stress_M64_2TData_P30_Low_Cache_Hit_5min_DiskIO.jpg?raw=true)

    - With M64, due to lower cache hit rate after VM boot, VM Max NONE CACHE IOPS limitation applied on DB node. 
    - Both Calibrate_IO and SLOB push disk IO near 2.5K on each disk.
    - Resize M64 to M128 which includes OS reboot, disk IO hit to 5000 when cache rate is low. 


### Test 3: P30S DB, Active Dataset (2T) >> 3GiB SGA. READ Percent=100%, 50% > Cache Hit > 30%
| VM Size | Max_IOPS | DISK | IOPS | QTR | RAC_IOPS  | CACHE | IOPS_RESULT |DB_S_R_WAIT |<32us|<64us|<128us|<256us|<512us|<1ms |<2ms |<4ms |<8ms |<16ms|<32ms|<64ms|<128ms|
| :---    |--------: |---:  |---:  |---: |--------:  | ---:  | ----------: |----------: |:--: |:--: |:--:  |:--:  |:--:  |:--: |:--: |:--: |:--: |:--: |:--: |:--: |:--:  |
| M128    | 80K/160K |P30   |  5K  |  32 | 160K      | R-WA  |   77K       |    6M      |-    |-    | 0.1  |6.0   |24.2  |8.5  |4.8  |43.0 |11.6 |1.2  |0.2  |0.1  |0.2   |
 
![Test 3](ScreenShot/SLOB_Stress_M128_2TData_P30_Medium_Cache_Hit_5min_DiskIO.jpg?raw=true)

    - With M128, it takes a while to load enough data to host cache so that Cache Hit rate to stable at medium level.
    - IO Latency is improved compare with Low cache hit.
    - Cache hit on two DB nodes are not balanced. As the Active Database size is pretty large, the scenario is reasonable.  

### Test 4: P60S DB, NONE CACHE on Data Disk, READ-ONLY + Write Accelerate on REDO Log. SCALE = 256M, SCHEMA count = 512.
| VM Size | Max_IOPS | DISK | IOPS | QTR | RAC_IOPS  | CACHE | IOPS_RESULT |DB_S_R_WAIT |<32us|<64us|<128us|<256us|<512us|<1ms |<2ms |<4ms |<8ms |<16ms|<32ms|<64ms|<128ms|
| :---    |--------: |---:  |---:  |---: |--------:  | ---:  | ----------: |----------: |:--: |:--: |:--:  |:--:  |:--:  |:--: |:--: |:--: |:--: |:--: |:--: |:--: |:--:  |
| M128    | 80K/160K |P60   | 16K  |  8  | 128K      | N-WA  |     80K     |   2.3M     |-    |-    | -    |-     |-     |-    |-    |31.3 |42.8 |14.3 |4.5  |3.7  |2.9   |

![Test 4](ScreenShot/SLOB_Stress_M128_256GData_P60_No_Cache_10min_DiskIO.jpg?raw=true)

    - Since VM IOPS limit is 80K. the IOPS tested result is the sum of two nodes.
    - Workload is not balanced in the test, node 2 used up all the disk capacity due to sessions not evenly balanced in two nodes.
    - P60 provide high IOPS per disk, while latency is same as other P-SSD, like P30, with READ-ONLY cache disabled. 

# Learning: 

- FlashGrid SkyCluster is able to support Oracle RAC on cloud with high IO throughput.
- Push the Premium Data Disk IOPS to limitation does not impact Oracle OS Stability
- P-SSD with large VM host cache can provide over 100K IOPS with very low latency(<1ms with high cache hit rate)
- Disk with READ-ONLY CACHE is helpful to improve the IO performance. 
- Without U-SSD in China, alterntive solution to use P-SSD with cache and Write Accelerate.
- Precise calculate workload and data volume before select Disk/VM size. 
- Use disks under 4T can be a good option, if it can provide required capacity. 
