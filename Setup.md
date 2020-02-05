**FlashGrid on Azure China**

FlashGrid DOC for global Azure.

   - [White Paper for Oracle RAC on FlashGrid on Azure](https://www.flashgrid.io/wp-content/sideuploads/resources/FlashGrid_OracleRAC_in_Azure.pdf)  
   - [SkyCluster Deployment Guide](https://www.flashgrid.io/wp-content/sideuploads/resources/FlashGrid_SkyCluster_Deployment_Guide_for_Azure.pdf)  

Facts on China Azure.

- Pared Region: China East - China North, China East 2 - China North 2
- No Availability Zone in China regions
- 2 Fault Domains in Availability Set of each region 

**SkyCluster Quick Launcher**

- Database node:  

    |  VM Size  | vCore  | RAM      | Local SSD |  L-SSD  (IOPS / MBps / Cache GiB)  | Max IOPS |  Max Disks   | Max Bandwidth  |
    |  ----     | ----   | ----     | ----      |  ----                              | ----     |  ----        |  ----          |
    |  E16s v3  | 16     | 128 GiB  | 256 GiB   |  32000 / 256 (400)                 |  25600   |  32          |  8000 Mbps     |
    |  E64s v3  | 64     | 432 GiB  | 864 GiB   |  128000 / 1024 (1600)              |  80000   |  32          |  30000 Mbps    |
    |  M64      | 64     | 1024 GiB | 2000 GiB  |  80000 / 800 (1228)                |  40000   |  64          |  16000 Mbps    |


- Quorum node

    |  VM Size  | vCore  | RAM      | Local SSD | Max IOPS |  Max Data Disks |
    |  ----     | ----   | ----     | ----      | ----     |  ----       |
    |  D2s v3   | 2      | 8 GiB    | 16 GiB    | 3200     |  4          | 

- Software

    |  OS       | Oracle  | FlashGrid      | 
    |  ----     | ----    | ----           | 
    |  RHEL 7   | 12.2     | x             | 

- Architecture

    [Visio File link]

**FlashGrid SkyCluster Launcher**

    Preparation: please contact flashgrid to get vhd image and configuration template file. then go to https://1910.cloudprov.flashgrid.io/ to upload the configuration file and continue the wizard.


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

    Ensure the data is saved in File Share with acceptable performance within China, like China Azure Blob storage https://chinaracpoc.blob.core.chinacloudapi.cn/software. 

    https://allenklab.blob.core.windows.net/flashgrid


    SkyCluster Launcher checks file existance only, not MD5. it is YOUR responsibility to verify packages are safe to deploy. For test purpose, we can create files so SkyCluster Launcher can continue.

4. Nodes
   -   Availability Zones or Fault Domains: No AZ, 2 Fault Domains
   -   Cluster Node: Select based on workload. Refer to [IO Test Result]

5. Storage:
   - Select storage based on capacity and performance. Large Singl Disk = Higher Performance.
   - ASM Capacity does not equal to all the disk attached in the cluster due to redudant.

6. Memory
   - Automatically configure HugePages - Checked. 
   - % of System Memory allocated for Databases (SGA+PGA) - 80 (default)
   - % of the Database Memory allocated for SGA - 60 (default)

7. Listener Ports: 
   - SCAN listener Port: 1521
   - Local listener Port: 1522

8. Network: 
   - Create new VNet: Unchecked. Prefer to configure network environment before deploy Oracle RAC. In most case, network topology should has been designed before Oracle RAC. Ensure requird port are allowed in the RAC subnet.
   - Assign Public IPs to Cluster Nodes: keep it unchecked for secure purpose. Servers should be able to access requird internet service, like NTP server through default Azure SNAT egress.

9. DNS
    
    - Inter-Cluster communcation is handled by
    - DNS is required for cluster external communication

10. Time Zone

https://docs.azure.cn/zh-cn/virtual-machines/linux/time-sync, need to verify from FlashGrid Image.

The default configuration for Azure Marketplace images uses both NTP time and VMICTimeSync host-time.
Host-only using VMICTimeSync.
Use another, external time server with or without using VMICTimeSync host-time.

- Time Zone: Asia/Shanghai
- NTP Servers: 

	   server 0.cn.pool.ntp.org
	   server 1.cn.pool.ntp.org
	   server 2.cn.pool.ntp.org
	   server 3.cn.pool.ntp.org

https://www.pool.ntp.org/zone/cn

1.  Alert
2.  Tags
3.  Validate
4.  Launch

**Deploy ARM Template**

1. At the end of the SkyCluster Launcher, a cfg file will be saved to keep all the configuration in the wizard. 

2. Launch the deployment process, FlashGrid will launch Azure China Portal for resource deployment. As China Azure does not have required image in MarketPlace, contact FlashGrid directly to get VHD and configure file. 

    a. Convert VHD as an OS Image in China Azure subscription.
    b. Modify the CNF file to change the image Resource ID we just created.  
    c. Upload the new CNF file to flashgrid launcher wizard, go through the wizard again to make necessary changes.
    d. Before deploy the resource, save the configration again for further usage.
    e. Deploy SkyCluster. It is better to save the JSON template in case any manual changes requires. 

