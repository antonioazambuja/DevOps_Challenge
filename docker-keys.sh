#!/bin/bash

echo 'export DOCKER_USERNAME='$1 >> /etc/environment
echo 'export DOCKER_PASSWORD='$2 >> /etc/environment
source /etc/environment
exit 0
