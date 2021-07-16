RESOURCE_GROUP=""
NODE_NAME=""
NUM=1
while read line; do
	if (( $NUM % 3 == 0 ))
    then
        RESOURCE_GROUP="PROD-Render";
    elif (( $NUM % 3 == 2 ))
    then
		RESOURCE_GROUP="PROD-Render-japaneast";
    elif (( $NUM % 3 == 1 ))
    then
        RESOURCE_GROUP="PROD-Render-eastasia";
    fi
    
	NODE_NAME=$line;
    echo ${NODE_NAME}
    NODE_IP=$(az vm show -d -g ${RESOURCE_GROUP} -n ${NODE_NAME} --query publicIps -o tsv)
    ssh -o StrictHostKeyChecking=no -i /var/lib/jenkins/.ssh/azure/prod-render azureuser@${NODE_IP} "sudo sh /render/stop.sh || true" </dev/null
    
    # delete resource
    INTERFACE_ID=$(az vm show --resource-group ${RESOURCE_GROUP} --name ${NODE_NAME} --query networkProfile.networkInterfaces[0].id)
	INTERFACE_ID=${INTERFACE_ID:1: -1}
	OS_DISK_ID=$(az vm show --resource-group ${RESOURCE_GROUP} --name ${NODE_NAME} --query storageProfile.osDisk.managedDisk.id)
	OS_DISK_ID=${OS_DISK_ID:1: -1}
    SECURITY_GROUP_ID=$(az network nic show --id ${INTERFACE_ID} --query networkSecurityGroup.id)
    SECURITY_GROUP_ID=${SECURITY_GROUP_ID:1: -1}
    PUBLIC_IP_ID=$(az network nic show --id ${INTERFACE_ID} --query ipConfigurations[0].publicIpAddress.id)
    PUBLIC_IP_ID=${PUBLIC_IP_ID:1: -1}
    
    az vm delete --resource-group ${RESOURCE_GROUP} --name ${NODE_NAME} --yes
    echo "Deleted vm: ${NODE_NAME} in resource group ${RESOURCE_GROUP}"
    az network nic delete --id ${INTERFACE_ID}
    echo "Deleted network interface: ${INTERFACE_ID}"
    az disk delete --id ${OS_DISK_ID} --yes
    echo "Deleted os disk: ${OS_DISK_ID}"
    az network nsg delete --id ${SECURITY_GROUP_ID}
    echo "Deleted network security group:${SECURITY_GROUP_ID}"
    az network public-ip delete --id ${PUBLIC_IP_ID}
    echo "Deleted public ip: ${PUBLIC_IP_ID}"
    
    
    NUM=$((NUM+1))
done < /tmp/azure-node-name.txt

sudo rm -f /tmp/azure-node-name.txt
