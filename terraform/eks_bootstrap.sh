#!/bin/bash
set -ex

#YOU MUST NOT CONTAIN ANY KOREAN TEXT IN THIS FILE IT MAKES UNICODE ENCODING ERRORS!!!

# # Enable SSH password authentication
# sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# systemctl restart sshd
# install jq, awscli (Amazon Linux 2, can omit if already installed)
yum install -y awscli jq

# Secrets Manager (modify region and secret-id as needed)
SECRET=$(aws secretsmanager get-secret-value --region ap-northeast-2 --secret-id serial-password --query SecretString --output text)
PASSWORD=$(echo $SECRET | jq -r '.password')

# ㅊcreate a new user and set password
useradd eks-admin
echo "eks-admin:$PASSWORD" | chpasswd

/etc/eks/bootstrap.sh ${cluster_name} \
  --b64-cluster-ca ${cluster_ca} \
  --apiserver-endpoint ${cluster_endpoint} \
  --kubelet-extra-args "--node-labels=eks.amazonaws.com/nodegroup-image=ami-0e2091959fdebe0dc,eks.amazonaws.com/capacityType=ON_DEMAND" \
  --use-max-pods false