#!/bin/bash

echo 'export TF_VAR_MY_IP='$(dig +short myip.opendns.com @resolver1.opendns.com) >> /etc/environment
echo 'export TF_VAR_aws_access_key='$(aws configure get aws_access_key_id) >> /etc/environment
echo 'export AWSAcessKeyId='$(aws configure get aws_access_key_id) >> /etc/environment
echo 'export AWSSecretKey='$(aws configure get aws_secret_access_key) >> /etc/environment
echo 'export TF_VAR_aws_secret_key='$(aws configure get aws_secret_access_key) >> /etc/environment
echo 'export TF_VAR_aws_region='$3 >> /etc/environment
source /etc/environment
exit 0
