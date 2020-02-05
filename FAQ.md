**Pre-Deployment**

    Q: Can we have a free trail before production?
    A: Yes, the requst can be submitted from https://www.flashgrid.io/skycluster-in-azure-free-trial/
    
    Q: Any problem to access FlashGrid official portal?
    A: if any troulbes to submit request or launch FlashGrid Launcher, better connect from a enviornment beyond China Great Firewall. Component like reCAPTCHA from FlashGrid office web site cannot work inside China.

    Q: There is not RHEL and FlashGrid image in China Azure Market Place, how can I start the production/trail deployment?
    A: Please contact FlashGrid to get image VHD and convert it as a VM image in your China Azure subscription. The VHD file is located on global Azure. It is better we have mirror site on China Azure blob service. 

    Sample script to convert the vhd to image. Assume the vhd (flashgrid-rhel-os.vhd) is saved in storage account mcsacn2racpoc with container named images.

        # login to China Azure
        Add-AzAccount -Environment AzureChinaCloud

        # Set image configuration. Sample deployment target region is China North 2.
        $imageConfig = New-AzImageConfig -Location 'China North 2';
        $osDiskVhdUri = "https://mcsacn2racpoc.blob.core.chinacloudapi.cn/images/flashgrid-rhel-os.vhd"
        Set-AzImageOsDisk -Image $imageConfig -OsType 'Linux' -OsState 'Generalized' -BlobUri $osDiskVhdUri;

        # Replace with your image name and target resource group name.
        New-AzImage -Image $imageConfig -ImageName 'YourImageName' -ResourceGroupName 'YourResourceGroup';

    Q: Do i need license for RHEL?
    A: sudo subscription-manager  list

        +-------------------------------------------+
        Installed Product Status
        +-------------------------------------------+
        Product Name:   dotNET on RHEL (for RHEL Server)
        Product ID:     317
        Version:        2.0
        Arch:           x86_64
        Status:         Unknown
        Status Details: 
        Starts:         
        Ends:           

        Product Name:   Red Hat Enterprise Linux Server
        Product ID:     69
        Version:        7.7
        Arch:           x86_64
        Status:         Unknown
        Status Details: 
        Starts:         
        Ends:           


**Deployment**

    Q: Deployment Size from SkyCluster Launcher does not match with China VM Size, how to choose?
    A: While selecting the node size, the size listed on FlashGrid portal, like E16s_v3: 8 Cores, 128 GiB, storage: 32 disks max 384MB/s, 25600 IOPS, does not match with cores on https://docs.azure.cn/zh-cn/virtual-machines/windows/sizes-memory. As Azure sizing the VM as vCores and Esv3-series VM's feature Intel® Hyper-Threading Technology, it should be the same. In case there is any sizing mis-match, the real VM sizing info is determined by Azure platform.

    Q: Shall we enable Accelerated Networking to pass through host Network?
    A: Accelerated Networking is automatically enabled after deployment.

    Test Image from FlashGrid as following version which should be able to support Accelerated Networking.

        Operating System: Red Hat Enterprise Linux Server 7.7 (Maipo)
        CPE OS Name: cpe:/o:redhat:enterprise_linux:7.7:GA:server
        Kernel: Linux 3.10.0-1062.7.1.el7.x86_64

    Q: Max cached and temp storage throughput is higher than VM un-Cached throughput, Does SkyCluster make any usage of the local temp SSD?
    A: 

    Q: Usable_Capacity = Number_of_Disks_per_Node x Disk_Size (because of mirroring between the nodes)? 
    A: The total SSD assigned to the cluster cannot be fully used by ASM due to redudant(mirror). So the ASM Usable_Capacity = Number_of_Disks_per_Node x Disk_Size x Node_Count / Redudant_Factor. For the two node cluster, Node_Count = Redudant_Factor = 2. 

**Post-Deployment**
    
    Q: After deploy the FlashGrid cluster to one subscription. does it support to move to different subscription?
    A: The subscription ID does not matter in China as it is not charged via MarketPlace in China. The cluster resources can be managed as normal resources. 

    Q: What is the usage for flashgrid-client-nsg?
    A: A Network Security Group resource, flashgrid-client-nsg, is created during the deployment but it does not associate with any subnet/nic. please review the rules to ensure if meet your network requirement.  

        Port required by FlashGrid
        - UDP 4801, 4802, 4803 and TCP 3260 between the cluster node VMs
        - TCP ports 1521 (or customized SCAN Listener port) and 1522 (or customized Local Listener port) for client and app server access
        - TCP port 22 for SSH access

    Q: what is the common CLI to verify SkyCluster has been configured properly?
    A: sudo flashgrid-cluster verify

    Q: Time Sync requirement for FlashGrid?
    A: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/time-sync

        - NTP
        - Chrony Service 

            chronyc sources -v
            cat /etc/chrony.conf 

        - Oracle CTSS sync time before DB node, not quorum node

    Q: The deployment is reported as successful but there is not fg-pri virtual NIC on quorum node. Also, there other virtual NIC is created on DB node. is it normal?


    Q: Does it have IPv6 support?


    Q: How manage disk created by the SkyCluster Launcher.
    A: Besides the disk added in the ASM, there are another two disk created: 107GiB disk for install Oracle. One 5 GiB Disk attached for Grid usage. 
    
    OS disk
        --------------------------------------------------------------------------------------------------------
        Name                Size        Storage account type        Encryption        Host caching
        --------------------------------------------------------------------------------------------------------
        mcracpoc1-vm-root   32 GiB      Premium SSD                 Not enabled       Read-only
        --------------------------------------------------------------------------------------------------------

    Data disks
        --------------------------------------------------------------------------------------------------------
        LUN         Name                      Size        Storage account type        Encryption        Host caching
        --------------------------------------------------------------------------------------------------------
        0           disks_mcracpoc1_lun0_xxx  107 GiB     Premium SSD                 Not enabled       Read-only
        1           disks_mcracpoc1_lun1_xxx  5 GiB       Premium SSD                 Not enabled       Read-only
        2           disks_mcracpoc1_lun2_xxx  1024 GiB    Premium SSD                 Not enabled       Read-only
        3           disks_mcracpoc1_lun3_xxx  1024 GiB    Premium SSD                 Not enabled       Read-only
        4           disks_mcracpoc1_lun4_xxx  1024 GiB    Premium SSD                 Not enabled       Read-only
        5           disks_mcracpoc1_lun5_xxx  512 GiB     Premium SSD                 Not enabled       Read-only
        6           disks_mcracpoc1_lun6_xxx  512 GiB     Premium SSD                 Not enabled       Read-only
        7           disks_mcracpoc1_lun7_xxx  512 GiB     Premium SSD                 Not enabled       Read-only
        --------------------------------------------------------------------------------------------------------
    
    SkyCluster Layout
        --------------------------------------------------------------------------------------------------------
        GroupName  Status  Mounted   Type    TotalMiB  FreeMiB  OfflineDisks  LostDisks  Resync  ReadLocal  Vote
        --------------------------------------------------------------------------------------------------------
        DATA       Good    AllNodes  NORMAL  6291456   6291072  0             0          No      Enabled    None
        FRA        Good    AllNodes  NORMAL  3145728   3145344  0             0          No      Enabled    None
        GRID       Good    AllNodes  NORMAL  10240     9496     0             0          No      Enabled    3/3 
        --------------------------------------------------------------------------------------------------------

**IO Stress Test**

    Q: what is the IO Stack difference w/o ReadLocal?
    A: 

    Q: Max number of Data disk changes alone with the VM size? any best practise/suggest about the disk group?
    A: 

    Q: VM Shutdown process/sequence?
    A: link "https://kb.flashgrid.io/maintenance" does not work.

    Q: How to rename DiskGroup DATA -> P30?
    A: 


    Q: Do I have to distrubute the storage to node equally? Can i add 1 disk on node 1 and two disk on Node 2 for one DG?
    A: 

    Q: Can I use disk size ovre 4T Premium SSD? disk size over 4TB does not support ReadOnly/ReadWrite Cache.
    A:

    Q: does is matter for "The number of quorum disks is fewer than the recommended minimum of 1 for this disk group configuration"?
    A: as the main task is to test IO performance. only two disks are added to the DiskGroup. the group state is Good now. after cluster reboot.

    Q: what is the suggested process for creating DB on P30, P60 and P80 DG for IO Stress Test? situaitons like:
    
        - AU size recommend for differnent DG due to disk size?
        - sperate data file and REDO log to different DG
        - do i need to manaually config SPA and PGA everytime when scaling?
    A: 

    Q: Shall we enable SWAP disk. when creating DB, this is warning for SWAP space is too small. by default Azure VM does not create SWAP on Temp disk.
    A: 

