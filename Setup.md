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

    VM Size    vCore    RAM           Max IOPS    MAX Throughput    Max Disks    Max Network Bandwidth  
    ----       ----     --------      --------    ---------------   ----------   ----------------------
    D8s v3     8        32 GiB        12800       192MB             16           8000 Mbps
    E32s v3    32       256 GiB       51200       768MB             32           30000 Mbps
    M64        64       1024 GiB      40000       1000MB            64           16000 Mbps


- Quorum node

    VM Size    vCore    RAM           Max IOPS    MAX Throughput    Max Disks    Max Network Bandwidth  
    ----       ----     --------      --------    ---------------   ----------   ----------------------
    D2s v3      2       8 GiB         3200       48MB              4            1000Mbps

- Software

    OS          Oracle      FlashGrid 
    -------     --------    -----------
    RHEL 7      19.2        

- Architecture

    [Visio File link]

**FlashGrid SkyCluster Launcher**

    Preparation: contact flashgrid to get vhd image and configuration template file. 
    
   1. Convert VHD as an OS Image in China Azure subscription. Check FAQ for a sample PowerShell code.
   2. Modify the configuration file to replace the image with the new created Image resource ID.
   3. Go to https://1910.cloudprov.flashgrid.io/ to upload the modified configuration file and continue the wizard
   4. Before deploy the resource, better to save the configration file for further usage.
   5. Lauch the deployment and broswer goes to China Azure Portal for ARM template deployment. 
   6. Save the JSON template before create resource in Azure.
   7. Deploy the resource on China Azure.

**Configuration for Each Step**

  1. Cluster Info

      Cluster Name    Cloud Type    OS         Production or Trial   SSH key 
      ------------    ----------    ----       ------------------    --------
      mcracpoc        China         RHEL 7     Trial                   ----

  2. Database Version

  3. Oracle Files

      Ensure the data is saved in File Share with acceptable performance within China, like China Azure Blob storage https://storageaccountname.blob.core.chinacloudapi.cn/software. SkyCluster Launcher checks file existance only, not MD5. it is YOUR responsibility to verify packages are safe to deploy. For test purpose to just go through the wizard, we can create files with same name so SkyCluster Launcher can continue.

      If PoC environment has no Internet access, setup Service End Point for vNET access.

  4. Nodes
     -   Availability Zones or Fault Domains: No AZ, 2 Fault Domains
     -   Cluster Node: Select based on workload. 

  5. Storage:
     - Select storage based on capacity and performance. Large Singl Disk = Higher Performance. Better less than 4TB

  6. Memory
     - Automatically configure HugePages - Checked. 
     - % of System Memory allocated for Databases (SGA+PGA) - 80 (default)
     - % of the Database Memory allocated for SGA - 60 (default)

  7. Listener Ports: 
     - SCAN listener Port: 1521
     - Local listener Port: 1522

  8.  Network: 
     - Create new VNet: Unchecked. Prefer to configure network environment before deploy Oracle RAC. In most case, network topology should has been designed before Oracle RAC. Ensure requird port are allowed in the RAC subnet.
     - Assign Public IPs to Cluster Nodes: keep it unchecked for secure purpose. Without public IP, nodes can still access requird internet service, like NTP server through default Azure SNAT egress.

  9.  DNS
      - Inter-Cluster communcation is handled by cluster. 
      - DNS is required for cluster external communication

  10. Time Zone

  - Time Zone: Asia/Shanghai
  - Sample NTP Servers. make sure to use one, cluster deploy may fail if keep it blank, even though Azure sync the time with host, FlashGrid Cluster manually check this during cluster initilization 

  	   server 0.cn.pool.ntp.org
  	   server 1.cn.pool.ntp.org
  	   server 2.cn.pool.ntp.org
  	   server 3.cn.pool.ntp.org

  11. Alert
  12. Tags
  13. Validate
  14. Launch


