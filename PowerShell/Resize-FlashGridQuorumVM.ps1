# Change Quorum Node availablity set after deployment. 
# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/change-availability-set


# Set variables
    $resourceGroup = "mc-rg-nielson-rac"
    $vmName = "mcracpocq-vm"
    $newAvailSetName = "mcracpocq-as"
    $newVMSize = "Standard_D4s_v3"

# Get the details of the VM to be moved to the Availability Set
    $originalVM = Get-AzVM `
	   -ResourceGroupName $resourceGroup `
	   -Name $vmName

# Create new availability set if it does not exist
    $availSet = Get-AzAvailabilitySet `
	   -ResourceGroupName $resourceGroup `
	   -Name $newAvailSetName `
	   -ErrorAction Ignore
    if (-Not $availSet) {
    $availSet = New-AzAvailabilitySet `
	   -Location $originalVM.Location `
	   -Name $newAvailSetName `
	   -ResourceGroupName $resourceGroup `
	   -PlatformFaultDomainCount 2 `
	   -PlatformUpdateDomainCount 2 `
	   -Sku Aligned
    }
    
# Remove the original VM
    Remove-AzVM -ResourceGroupName $resourceGroup -Name $vmName    

# RESET the VM Here 
# Create the basic configuration for the replacement VM. replace $originalVM.HardwareProfile.VmSize with a new size
    $newVM = New-AzVMConfig -VMName $originalVM.Name -VMSize  $newVMSize -AvailabilitySetId $availSet.Id
    	  
 
# For a Linux VM, change the last parameter from -Windows to -Linux 
    Set-AzVMOSDisk `
	   -VM $newVM -CreateOption Attach `
	   -ManagedDiskId $originalVM.StorageProfile.OsDisk.ManagedDisk.Id `
	   -Name $originalVM.StorageProfile.OsDisk.Name `
	   -Linux

# Add Data Disks, note to change the disk cache to readonly
    foreach ($disk in $originalVM.StorageProfile.DataDisks) { 
    Add-AzVMDataDisk -VM $newVM `
	   -Name $disk.Name `
	   -ManagedDiskId $disk.ManagedDisk.Id `
	   -Caching ReadOnly `
	   -Lun $disk.Lun `
	   -DiskSizeInGB $disk.DiskSizeGB `
	   -CreateOption Attach

    }

   
# Add NIC(s) and keep the same NIC as primary
	foreach ($nic in $originalVM.NetworkProfile.NetworkInterfaces) {	
	if ($nic.Primary -eq "True")
		{
    		Add-AzVMNetworkInterface `
       		-VM $newVM `
       		-Id $nic.Id -Primary
       		}
       	else
       		{
       		  Add-AzVMNetworkInterface `
      		  -VM $newVM `
      	 	  -Id $nic.Id 
                }
  	}

# Recreate the VM
    New-AzVM `
	   -ResourceGroupName $resourceGroup `
	   -Location $originalVM.Location `
	   -VM $newVM `
	   -DisableBginfoExtension
