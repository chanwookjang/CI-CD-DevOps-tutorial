#!/bin/bash
set -ex
echo ttyS0 >> /etc/securetty # Enable serial console login

# in 64bit sys, pam_securetty.so path modification
if grep -q pam_securetty.so /etc/pam.d/login; then
  sed -i 's|auth\s\+required\s\+/lib/security/pam_securetty.so|auth required /usr/lib64/security/pam_securetty.so|' /etc/pam.d/login
fi

#/sbin/unix_chkpwd rights modification
chmod 4755 /sbin/unix_chkpwd || true

#YOU MUST NOT CONTAIN ANY KOREAN TEXT IN THIS FILE IT MAKES UNICODE ENCODING ERRORS!!!
# # Enable SSH password authentication
# sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# systemctl restart sshd
# install jq, awscli (Amazon Linux 2, can omit if already installed)
yum install -y awscli jq

# Before password setting, add validation:
echo "Retrieved secret: $SECRET"  # Check if secret exists
echo "Extracted password: $PASSWORD"  # Verify password extraction

# Secrets Manager (modify region and secret-id as needed)
SECRET=$(aws secretsmanager get-secret-value --region ap-northeast-2 --secret-id serial-password --query SecretString --output text)
PASSWORD=$(echo $SECRET | jq -r '.["serial-password"]') 
#if serialkey name in json contains -, , @,. then use jp -r '.["jsonkey"]' or jq -r .password

# Change from simple useradd to:
useradd -m -s /bin/bash eks-admin  # -m creates home dir, -s sets shell
echo "eks-admin:$PASSWORD" | chpasswd || echo "Password change failed!"

/etc/eks/bootstrap.sh ${cluster_name} \
  --b64-cluster-ca ${cluster_ca} \
  --apiserver-endpoint ${cluster_endpoint} \
  --kubelet-extra-args "--node-labels=eks.amazonaws.com/nodegroup-image=ami-0e2091959fdebe0dc,eks.amazonaws.com/capacityType=ON_DEMAND" \
  --use-max-pods false
