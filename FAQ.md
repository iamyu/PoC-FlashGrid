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


**Deployment**

    Q: Deployment Size from SkyCluster Launcher does not match with China VM Size, how to choose?
    A: While selecting the node size, the size listed on FlashGrid portal, like E16s_v3: 8 Cores, 128 GiB, storage: 32 disks max 384MB/s, 25600 IOPS, does not match with cores on https://docs.azure.cn/zh-cn/virtual-machines/windows/sizes-memory. As Azure sizing the VM as vCores and Esv3-series VM's feature Intel® Hyper-Threading Technology, it should be the same. In case there is any sizing mis-match, the real VM sizing info is determined by Azure platform.

    Q: Shall we enable Accelerated Networking to pass through host Network?
    A: 

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

    Q: what is the common CLI to verify SkyCluster has been configured properly?
    A: 