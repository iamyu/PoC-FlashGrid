**FlashGrid on Azure China**

Facts on China Azure.

- Pared Region: China East - China North, China East 2 - China North 2
- No Availability Zone in China regions
- 2 Fault Domains in Availability Set of each region 

**Environment**

- Database node:  

    |  VM Size  | vCore  | RAM      | Local SSD | Max IOPS |  Data Disks  |
    |  ----     | ----   | ----     | ----      | ----     |  ----        |
    |  E16s v3  | 16     | 128 GiB  | 256 GiB   |  25600   |  32          | 
    |  E64s v3  | 64     | 432 GiB  | 864 GiB   |  80000   |  32          | 
    |  M64      | 64     | 1024 GiB | 2000 GiB  |  40000   |  64          | 


- Quorum node

    |  VM Size  | vCore  | RAM      | Local SSD | Max IOPS |  Data Disks |
    |  ----     | ----   | ----     | ----      | ----     |  ----       |
    |  D2s v3   | 2      | 8 GiB    | 16 GiB    | 3200     |  4          | 


- Architecture
 

- Target SLA



