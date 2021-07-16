ZONE="asia-east2-a"

for ((NUM=1; NUM<=${INSTANCE_COUNT}; NUM++))
do
	if [ ${NUM} -eq 5 ];then
    	ZONE="asia-east1-a"
    fi
    
	NODE_NAME="gcp-render-${BUILD_NUMBER}-${NUM}"
    gcloud compute instances create ${NODE_NAME} \
            --zone=${ZONE} \
            --image-family="ubuntu-1804-lts" \
            --image-project="ubuntu-os-cloud" \
            --boot-disk-size=120GB \
            --machine-type="c2-standard-60"
    sudo bash -c "echo ${NODE_NAME} >> /tmp/gcp-node-name.txt"
done
        
sleep 60

ZONE="asia-east2-a"

for ((NUM=1; NUM<=${INSTANCE_COUNT}; NUM++))
do
	if [ ${NUM} -eq 5 ];then
    	ZONE="asia-east1-a"
    fi
    
	NODE_NAME="gcp-render-${BUILD_NUMBER}-${NUM}"
	gcloud compute instances add-tags ${NODE_NAME} --tags="consumer-28410" --zone=${ZONE}
	gcloud compute ssh ${NODE_NAME} --zone=${ZONE} --  "wget https://d2l2ao86ljwgu8.cloudfront.net/render-package/RenderPackage-${RENDER_PACKAGE_VERSION}.tar.gz && tar xvzf RenderPackage-${RENDER_PACKAGE_VERSION}.tar.gz && cd pkg && sudo sh install.sh ${DEPLOY_ENV} ${NODE_NAME} ${RENDER_VERSION}_${BUILD_NUMBER}" &
    if (( $NUM % 3 == 0 ))
    then
    	wait
    fi
done

wait
