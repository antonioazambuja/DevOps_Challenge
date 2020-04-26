#!/bin/bash

kubectl delete -f .
kops delete cluster --state s3://tema20-k8s --name clusters.k8s.local --yes
exit 0
