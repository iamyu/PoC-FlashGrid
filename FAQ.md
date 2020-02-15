**Pre-Deployment**

    Q: Can we have a free trail before production?
    A: Yes, the requst can be submitted from https://www.flashgrid.io/skycluster-in-azure-free-trial/
    
    Q: Any problem to access FlashGrid official portal?
    A: if any troulbes to submit request or launch FlashGrid Launcher, try to connect from a enviornment beyond China Great Firewall. Component like reCAPTCHA from FlashGrid office web site cannot work inside China.

    Q: There is not RHEL and FlashGrid image in China Azure Market Place, how can I start the production/trail deployment?
    A: Please contact FlashGrid to get image VHD and convert it as a VM image in your China Azure subscription. note the vhd may located in global Azure and it takes time to download.

    Sample script to convert the vhd to image. Assume the vhd (flashgrid-rhel-os.vhd) is saved in storage account mcsacn2racpoc with container named images.

        # login to China Azure
        Add-AzAccount -Environment AzureChinaCloud

        # Set image configuration. Sample deployment target region is China North 2.
        $imageConfig = New-AzImageConfig -Location 'China North 2';
        $osDiskVhdUri = "https://yourstorageaccountname.blob.core.chinacloudapi.cn/images/flashgrid-rhel-os.vhd"
        Set-AzImageOsDisk -Image $imageConfig -OsType 'Linux' -OsState 'Generalized' -BlobUri $osDiskVhdUri;

        # Replace with your image name and target resource group name.
        New-AzImage -Image $imageConfig -ImageName 'YourImageName' -ResourceGroupName 'YourResourceGroup';

    Q: Do i need subscription from RHEL and Oracle?
    A: Yes. The solution from flashgrid is to build the shared storage for ASM, no subscription for RHEL or Oracle are included in the image.


**Deployment**

    Q: Deployment Size from SkyCluster Launcher does not match with China VM Size, how to choose?
    A: While selecting the node size, the size listed on FlashGrid portal, like E16s_v3: 8 Cores, 128 GiB, storage: 32 disks max 384MB/s, 25600 IOPS, does not match with cores on https://docs.azure.cn/zh-cn/virtual-machines/windows/sizes-memory. As Azure sizing the VM as vCores and Esv3-series VM's feature Intel® Hyper-Threading Technology, it should be the same. In case there is any sizing mis-match, the real VM sizing info is determined by Azure platform.

    Q: Shall we enable Accelerated Networking to pass through host Network?
    A: Accelerated Networking is automatically enabled after deployment.

    Q: Max cached and temp storage throughput is higher than VM un-Cached throughput, Does SkyCluster make any usage of the temp SSD?
    A: No. Temp SSD is not used FlashGrid cluster setup.

    Q: Can I deploy the cluster with a small size DB node and scale to any other size when necessary.
    A: In theory, yes, SkyCluster and Azure VM support scale out. Actually, once the availability set is created, the AVset supported VM size has been prefined. For example, if the cluster is created with D8s_v3 DB Node, it can scale up to D and E series VMs. but most like, scale up to M or L series will fail.     

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
    A: sudo flashgrid-cluster verify. A broadcast message will be displayed after cluster setup, follow the suggestion for necessary actions. 

    Q: Time Sync requirement for FlashGrid, do i really need a external time source?
    A: According to https://docs.microsoft.com/en-us/azure/virtual-machines/linux/time-sync, Azure platform should be able to sync the VM time. During the cluster initlization, it will check the time sync status. Tested for no NTP server in the configuration wizard, the deployment failed. 

    Q: Does it have IPv6 support?
    A: IPv6 is disabled in the cluster nodes.

    Q: How manage disk created by the SkyCluster Launcher.
    A: Besides the disk added in the ASM, there are another two disk created in my test: 107GiB disk for install Oracle. One 5 GiB Disk attached for GRID DG. 
    
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


    Q: What is the IO Stack difference w/o ReadLocal?
    A: Have not get answer from Flashgrid.

    Q: Max number of Data disk changes alone with the VM size? any best practise/suggest about the disk group?
    A: when scale up/down the DB node, ensure the small VM size support the same number of disks. FlashGrid does not cover this.

    Q: VM Shutdown process/sequence?
    A: follow FlashGrid's online guide to reboot a node or turn off the cluster: https://kb.flashgrid.io/maintenance/maintenance-azure

    Q: How to rename DiskGroup name?
    A: FlashGrid does not provide this option after deployment. 

    Q: Do I have to distrubute the storage to node equally? Can i add 1 disk on node 1 and two disk on Node 2 for one DG?
    A: Yes, it is the requirement for ASM. keep the disk layout same on both node.

    Q: Can I use disk size ovre 4T Premium SSD? disk size over 4TB does not support ReadOnly/ReadWrite Cache.
    A: It is not supported/suggested to use NONE cache disk. Tested with P60 & P80, it does work. 

    Q: Shall we enable SWAP disk. when creating DB, there is warning for SWAP space is too small. by default Azure VM does not create SWAP on Temp disk.
    A: Does not matter. I ignore the warning and continue.

