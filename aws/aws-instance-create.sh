RENDER_VERSION=""
while read line; do
    RENDER_VERSION=$line
done < /tmp/render-module-version.txt


RESULT=$(aws ec2 run-instances --image-id ami-0ba5cd124d7a79612  --security-group-ids sg-03507d520762b38ca --instance-type c5n.18xlarge --count $INSTANCE_COUNT --key-name aws_server_key --block-device-mapping "[ { \"DeviceName\": \"/dev/sda1\", \"Ebs\": { \"VolumeSize\": 60 } } ]")

I_ID_ARR=()
for (( i=0; i<$INSTANCE_COUNT; i++ )) do
	I_ID=$(echo $RESULT | jq ".Instances[$i].InstanceId" | tr -d \");
    I_ID_ARR+=($I_ID)
	sudo bash -c "echo ${I_ID} >> /tmp/aws-nodes.txt"
done

echo 'Instance created'

sleep 60

echo 'Install render modules'

for (( i=0; i<$INSTANCE_COUNT; i++ )) do
	PUBLIC_DNS=$(aws ec2 describe-instances --filters "Name=instance-id,Values=${I_ID_ARR[$i]}" --query "Reservations[].Instances[].PublicDnsName")
    PUBLIC_DNS=$(echo $PUBLIC_DNS | jq ".[0]" | tr -d \")
    NODE_NAME="AWS_${I_ID_ARR[$i]}_${BUILD_NUMBER}_${i}"
	ssh -o StrictHostKeyChecking=no -i /var/lib/jenkins/.ssh/aws_server_key.pem ubuntu@$PUBLIC_DNS "wget https://{domain}/render-package/RenderPackage-${RENDER_PACKAGE_VERSION}.tar.gz && tar xvzf RenderPackage-${RENDER_PACKAGE_VERSION}.tar.gz && cd pkg && sudo sh install.sh ${DEPLOY_ENV} ${NODE_NAME} ${RENDER_VERSION}_${BUILD_NUMBER}" &
    if (( $i % 3 == 2 ))
    then
    	wait
    fi
done

wait

echo 'Finished'