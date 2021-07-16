ZONE=""
RESOURCE_GROUP=""

for ((NUM=1; NUM<=${INSTANCE_COUNT}; NUM++))
do  
	if (( $NUM % 3 == 0 ))
    then
    	ZONE="koreacentral";
        RESOURCE_GROUP="PROD-Render";
    elif (( $NUM % 3 == 2 ))
    then
    	ZONE="japaneast";
		RESOURCE_GROUP="PROD-Render-japaneast";
    elif (( $NUM % 3 == 1 ))
    then
    	ZONE="eastasia"
        RESOURCE_GROUP="PROD-Render-eastasia";
    fi
    
	NODE_NAME="Azure-render-${BUILD_NUMBER}-${NUM}"
    az vm create \
		  --resource-group ${RESOURCE_GROUP} \
		  --name ${NODE_NAME} \
		  --image UbuntuLTS \
		  --admin-username azureuser \
		  --size Standard_F72s_v2 \
		  --location ${ZONE} \
		  --ssh-key-values /var/lib/jenkins/.ssh/azure/prod-render.pub &

    sudo bash -c "echo ${NODE_NAME} >> /tmp/azure-node-name.txt"
    
    if (( $NUM % 3 == 0 ))
    then
        wait
    fi
done

wait


for ((NUM=1; NUM<=${INSTANCE_COUNT}; NUM++))
do  
	NODE_NAME="Azure-render-${BUILD_NUMBER}-${NUM}"
    
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
    
    az vm open-port --resource-group ${RESOURCE_GROUP} --name ${NODE_NAME} --port 28410
    
	NODE_IP=$(az vm show -d -g ${RESOURCE_GROUP} -n ${NODE_NAME} --query publicIps -o tsv)
    
	ssh -o StrictHostKeyChecking=no \
    	-i /var/lib/jenkins/.ssh/azure/prod-render \
        azureuser@${NODE_IP} "wget https://{domain}/render-package/RenderPackage-${RENDER_PACKAGE_VERSION}.tar.gz && tar xvzf RenderPackage-${RENDER_PACKAGE_VERSION}.tar.gz && cd pkg && sudo sh install.sh ${DEPLOY_ENV} ${NODE_NAME} ${RENDER_VERSION}_${BUILD_NUMBER}" &
	
    if (( $NUM % 3 == 0 ))
    then
    	wait
    fi
done

wait