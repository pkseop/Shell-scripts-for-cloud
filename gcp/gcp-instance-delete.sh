NODE_NAME=""
NUM=1
ZONE="asia-east2-a"
while read line; do
	if [ ${NUM} -eq 5 ];then
    	ZONE="asia-east1-a"
    fi
    
	NODE_NAME=$line;
    echo ${NODE_NAME}
	gcloud compute ssh ${NODE_NAME} --zone=${ZONE} --command="sudo sh /render/stop.sh || true" </dev/null &
    NUM=$((NUM+1))
done < /tmp/gcp-node-name.txt

wait

NUM=1
ZONE="asia-east2-a"
while read line; do
	if [ ${NUM} -eq 5 ];then
    	ZONE="asia-east1-a"
    fi
	NODE_NAME=$line;
    gcloud -q compute instances delete ${NODE_NAME} --zone=${ZONE} </dev/null
    NUM=$((NUM+1))
done < /tmp/gcp-node-name.txt

sudo rm -f /tmp/gcp-node-name.txt