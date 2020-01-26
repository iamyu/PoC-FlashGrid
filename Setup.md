**FlashGrid on Azure China**

FlashGrid DOC for global Azure.

   - [White Paper for Oracle RAC on FlashGrid on Azure](https://www.flashgrid.io/wp-content/sideuploads/resources/FlashGrid_OracleRAC_in_Azure.pdf)  
   - [SkyCluster Deployment Guide](https://www.flashgrid.io/wp-content/sideuploads/resources/FlashGrid_SkyCluster_Deployment_Guide_for_Azure.pdf)  

Facts on China Azure.

- Pared Region: China East - China North, China East 2 - China North 2
- No Availability Zone in China regions
- 2 Fault Domains in Availability Set of each region 

**Environment**

- Database node:  

    |  VM Size  | vCore  | RAM      | Local SSD | Max IOPS |  Max Data Disks  |
    |  ----     | ----   | ----     | ----      | ----     |  ----        |
    |  E16s v3  | 16     | 128 GiB  | 256 GiB   |  25600   |  32          | 
    |  E64s v3  | 64     | 432 GiB  | 864 GiB   |  80000   |  32          | 
    |  M64      | 64     | 1024 GiB | 2000 GiB  |  40000   |  64          | 


- Quorum node

    |  VM Size  | vCore  | RAM      | Local SSD | Max IOPS |  Max Data Disks |
    |  ----     | ----   | ----     | ----      | ----     |  ----       |
    |  D2s v3   | 2      | 8 GiB    | 16 GiB    | 3200     |  4          | 

- Software

    |  OS       | Oracle  | FlashGrid      | 
    |  ----     | ----    | ----           | 
    |  RHEL 7   | 12.2     | x             | 

- Architecture


**FlashGrid SkyCluster Launcher**

1. Cluster Info

    |  Cluster Name  | Cloud Type  | OS      |  Production or Trial | SSH key |
    |  ----          | ----        | ----    |  ----                |  ----   |
    |  ChinaRACPoC   | China       | RHEL 7  |  Trial               |  FAKE    |

    A fake ssh key: 
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjNe1/dmr9Nxb6dfShmuvri+5kb38nvY3Vo6IBqIquLPUHLx1Q2OlFOSpX0m1ln4DLxha/i2i/b3JBbh80AIucUHoXUQrt8nWirOjG4g0M7i4j7Uc+UDMoGw21vwwSd/HwPesq+ZE/QCnRXOz/0+RSGzpFXSs76Cj7wyTHkJTepBjQ2ZKsB9ZyntksiN1U94175usxtZp4jXomg6ubm0PwnBcd/oWyucFy/5WGwwEtDy75nbLrgDru/G9sRmxnls82qxwahhjBauygFCb+R3c31aIl5xOBFOIuSWkNSa888f7m36wfSSHnzYKQF6ZeVJj5WA+R46gHKd1IgExGI11p

2. Database Version

    |  DB Software      | DB Version  | DB PSU/RU      | 
    |  ----             | ----        | ----           | 
    |  Yes              | 12.2.0.1 EE | 2019-10-15     | 

3. Oracle Files

   - LINUX.X64_193000_grid_home.zip - Oracle Database 19c Grid Infrastructure (19.3) for Linux x86-64
   - linuxx64_12201_database.zip - Oracle Database 12c Release 2 (12.2.0.1.0) for Linux x86-64
   - oracle-instantclient19.3-basic-19.3.0.0.0-1.x86_64.rpm - Oracle Instant Client Basic 19.3.0.0.0 for Linux x86-64
   - p30116789_190000_Linux-x86-64.zip - GI RELEASE UPDATE 19.5.0.0.0. **Requires Oracle support subscription.**
   - p30116802_122010_Linux-x86-64.zip - GI RELEASE UPDATE 12.2.0.1.191015. **Requires Oracle support subscription.**
   - p6880880_190000_Linux-x86-64.zip - OPatch 12.2.0.1.18 for DB 19.x releases, Platform: Linux x86-64. **Requires Oracle support subscription.**

    Sample URL: https://chinaracpoc.blob.core.chinacloudapi.cn/software  

