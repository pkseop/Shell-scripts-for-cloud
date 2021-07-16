while read line; do
	PUBLIC_DNS=$(aws ec2 describe-instances --filters "Name=instance-id,Values=${line}" --query "Reservations[].Instances[].PublicDnsName")
    PUBLIC_DNS=$(echo $PUBLIC_DNS | jq ".[0]" | tr -d \")
	ssh -o StrictHostKeyChecking=no -i /var/lib/jenkins/.ssh/aws_server_key.pem ubuntu@${PUBLIC_DNS} "sudo sh /render/stop.sh || true" </dev/null
	aws ec2 terminate-instances --instance-ids ${line}
done < /tmp/aws-nodes.txt

sudo rm -f /tmp/aws-nodes.txt