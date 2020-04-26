#!/bin/bash

aws s3api create-bucket --bucket tema20-k8s --region us-east-2 --create-bucket-configuration LocationConstraint=us-east-2
kops create cluster clusters.k8s.local --state s3://tema20-k8s --node-count 1 --node-size t2.medium --master-size t3.medium --master-zones us-east-2a --zones us-east-2a --kubernetes-version 1.15 --yes
until kubectl get pods | grep "No resources found in default namespace."
do 
    echo "Cluster not running"
    sleep 30
done
echo "Cluster running!"
kubectl apply -f .
exit 0
