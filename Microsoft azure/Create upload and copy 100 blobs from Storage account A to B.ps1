#Connect to my account in azure
Connect-AzAccount -TenantId 72f988bf-86f1-41af-91ab-2d7cd011db47

$resourceGroup = "rg_saar_home"

#Get all storage accounts in my resource Group where the Kind is StorageV2
$StorageAccounts = Get-AzStorageAccount -ResourceGroupName $resourceGroup | where Kind -EQ StorageV2 | sort -Property StorageAccountName



$srcStorage1Key = Get-AzStorageAccountKey -Name $StorageAccounts[0].StorageAccountName `
                                         -ResourceGroupName $resourceGroup 
  
$destStorage2Key = Get-AzStorageAccountKey -Name $StorageAccounts[1].StorageAccountName `
                                          -ResourceGroupName $resourceGroup

$srcStorage1Context = New-AzStorageContext -StorageAccountName $StorageAccounts[0].StorageAccountName `
                                   -StorageAccountKey $srcStorage1Key.Value[0]
 
$destStorage2Context = New-AzStorageContext -StorageAccountName $StorageAccounts[1].StorageAccountName `
                                    -StorageAccountKey $destStorage2Key.Value[0]

#Create new container in the first storage account
$saarstorage1ContainerName = 'container1'
New-AzStorageContainer -Name $saarstorage1ContainerName -Context $srcStorage1Context -Permission Blob

#Create new container in the second storage account
$saarstorage2ContainerName = 'container2'
New-AzStorageContainer -Name $saarstorage2ContainerName -Context $destStorage2Context -Permission Blob

#Check if C:\temp folder exist in my computer, if not exist create it
if(!(Test-Path -Path "C:\blobTemp"))
{
    New-Item -Path "C:\" -Name "blobTemp" -ItemType directory
}


#Create 100 txt files in the temp directory
for($i = 1;$i -le 100; $i++)
{
    New-Item -Path "C:\blobTemp" -ItemType File -Name "file$i.txt" -Force 
}

#take all the last 100 files  I created
$allTxtFiles = Get-ChildItem -Path "C:\blobTemp" | select -First 100 | sort -Property LastWriteTime

#craerte Blob for each file in the container that in the firs sotrage account
foreach($blobFile in $allTxtFiles)
{
    Set-AzStorageBlobContent -File $blobFile.FullName -Container $saarstorage1ContainerName -Blob $blobFile.Name -Context $srcStorage1Context
}

$destStorage2Key = Get-AzStorageAccountKey -Name $StorageAccounts[1].StorageAccountName `
                                          -ResourceGroupName $resourceGroup
$destStorage2Context = New-AzStorageContext -StorageAccountName $StorageAccounts[1].StorageAccountName `
                                    -StorageAccountKey $destStorage2Key.Value[0]


#get all the blobs from container1 of the first storage account and copy all the blobs to the container of the second storage account
Get-AzStorageBlob -Container $saarstorage1ContainerName -Context $srcStorage1Context | Start-CopyAzureStorageBlob -DestContainer $saarstorage2ContainerName -DestContext $destStorage2Context

