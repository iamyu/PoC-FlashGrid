$location = 'China North 2' # or "China East 2"

$ResourceGroupName = 'Resource Group that created already to host the Image Resource'
$StorageAccountName = 'Storage Account name to hos FlashGrid VHD file'
$ContainerName = 'Container to host the VHD'
$VHDBlobName = 'FlashGrid VHD File'

$ImageName = 'Image Name that you want to create'

Add-AzAccount -Environment AzureChinaCloud

$imageConfig = New-AzImageConfig -Location $location;
$osDiskVhdUri = "https://$StorageAccountName.blob.core.chinacloudapi.cn/$ContainerName/$VHDBlobName"
Set-AzImageOsDisk -Image $imageConfig -OsType 'Linux' -OsState 'Generalized' -BlobUri $osDiskVhdUri;

New-AzImage -Image $imageConfig -ImageName $ImageName -ResourceGroupName $ResourceGroupName;