### Install Azure command line tools
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash



### Login to azure using 

az login

### Create resource group  
az group create --name RG-file-share --location centralindia

### Create storage account in the resource group 
az storage account create --name praxfs10 --resource-group RG-file-share --location centralindia --sku Standard_LRS
 //In case subnsccription not found error is encountered, Visual Studio Professional Subscription | Resource providers, azure.storage should be regsitered

### Create a Storage Container
A container holds your blobs (files) within the storage account. We'll set the access level to public for easy sharing.




### Upload the Binary File, Now, upload your file (blob) to the container.

First create RBAC role is not present already 
1. get user id
USER_ID=$(az ad signed-in-user show --query id -o tsv)
echo "Your User ID is: $USER_ID"


### Storage account scope
#### Set variables for clarity (replace RG-file-share with your actual RG name)
RG_NAME="RG-file-share"
STORAGE_ACCOUNT_NAME="praxfs10"

#### Assign the 'Storage Blob Data Contributor' role
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee "$USER_ID" \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"

### Alternatievly resource group scope 
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee "$USER_ID" \
  --resource-group "$RG_NAME"



### 
az storage container create --name pub --account-name praxfs10 --public-access blob --auth-mode login



az storage blob upload \
  --container-name public-share \
  --account-name praxfs10 \
  --name MyLargeBinaryFile.zip \
  --file /path/to/your/local/MyLargeBinaryFile.zip \
  --auth-mode login



### Generate the Public Download URL
Once uploaded, the file is publicly accessible. The URL follows a simple format:

https://[StorageAccountName].blob.core.windows.net/[ContainerName]/[FileName]