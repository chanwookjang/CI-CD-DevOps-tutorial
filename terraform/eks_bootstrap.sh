#!/bin/bash
set -ex

#YOU MUST NOT CONTAIN ANY KOREAN TEXT IN THIS FILE IT MAKES UNICODE ENCODING ERRORS!!!

# Password setup (Change MySecurePassword123! as needed)
# echo 'ec2-user:1692' | chpasswd

# # Enable SSH password authentication
# sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# systemctl restart sshd

/etc/eks/bootstrap.sh ${cluster_name} \
  --b64-cluster-ca ${cluster_ca} \
  --apiserver-endpoint ${cluster_endpoint} \
  --kubelet-extra-args "--node-labels=eks.amazonaws.com/nodegroup-image=ami-0e2091959fdebe0dc,eks.amazonaws.com/capacityType=ON_DEMAND" \
  --use-max-pods false