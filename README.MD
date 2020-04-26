# Final Test - DevOps ilegra

In this project we provide an architecture with:
- Minimum two instances of micro service Calculator in Golang;
- Cluster Redis, Master and Slave;
- ELK Stack in K8S, using Amazon Kops;

## Summary

  - [Introduction](#introduction)

  - [Installation](#installations)

  - [Configuration](#configuration)

  - [Jobs](#configuration-docker)

## Introduction

This project is was proposed in study trail DevOps on ilegra. Tasks created provisioned in jobs Jenkins, were thought for an production enviroment.

## Installations

OBS: I will go through their official download sites, so that the latest version of each utility can be downloaded or execute an script `dependencies.sh` with root permissions:

```
$ sudo ./dependencies.sh
```

  - [Python 3](https://www.python.org/)

  - [AWS CLI](https://aws.amazon.com/pt/cli/)

  - [Packer](https://www.packer.io/)

  - [Terraform](https://www.terraform.io/)

  - [Docker](https://www.docker.com/)

  - [Java - Oracle](https://www.oracle.com/br/java/)

  - [Jenkins](https://jenkins.io/)

## Configuration

1. I created scripts to configure variables for Packer, Terraform and Jenkins;
    - Setting aws-cli:
        ```
        $ aws configure
        ```
    - Setting AWS keys:
        ```
        $ sudo ./aws-keys.sh AWS_REGION
        ```
    - Setting DOCKER keys:
        ```
        $ sudo ./docker-keys.sh DOCKER_USERNAME DOCKER_PASSWORD
        ```
    - Restart Jenkins service:
        ```
        $ sudo service jenkins restart
        ```
2. Create following key pairs in AWS Console:
    - tema20-calc
    - tema20-redis

## Jobs

1. Add your Github username and password in configurations for Jenkins acessing:

    - Manager Jenkins/Credentials;

2. Acess your Jenkins - http://localhost:8080/

### Baking

1. Baking AMI micro service Calculator in Golang: [`Estimated time = 6 minutes`]

- Description: Baking of AMI micro service Calculator Golang in AWS.

    - In the Pipeline category select: Pipeline script from SCM
    - In the SCM: Git
    - In the Repository URL add: `https://github.com/ilegra/jovens-talentos.git`
    - In the Credentials add your credentials of Github;
    - In the Script Path add: `3-devops/antonio-azambuja/tema20/baking-calc-ami/Jenkinsfile`

2. Baking AMI Redis: [`Estimated time = 6 minutes`]

- Description: Baking of AMI Redis in AWS.

    - In the Pipeline category select: Pipeline script from SCM
    - In the SCM: Git
    - In the Repository URL add: `https://github.com/ilegra/jovens-talentos.git`
    - In the Credentials add your credentials of Github;
    - In the Script Path add: `3-devops/antonio-azambuja/tema20/baking-redis-ami/Jenkinsfile`

3. Baking ELK Stack:

- Description: Baking of Docker containers for each soluction of ELK Stack. Images are at in your registry of DockerHub.

    1. Elasticsearch: [`Estimated time = 8 minutes`]
        - In the Pipeline category select: Pipeline script from SCM
        - In the SCM: Git
        - In the Repository URL add: `https://github.com/ilegra/jovens-talentos.git`
        - In the Credentials add your credentials of Github;
        - In the Script Path add: `3-devops/antonio-azambuja/tema20/baking-elk/elasticsearch/Jenkinsfile`
    2. Logstash: [`Estimated time = 8 minutes`]
        - In the Pipeline category select: Pipeline script from SCM
        - In the SCM: Git
        - In the Repository URL add: `https://github.com/ilegra/jovens-talentos.git`
        - In the Credentials add your credentials of Github;
        - In the Script Path add: `3-devops/antonio-azambuja/tema20/baking-elk/logstash/Jenkinsfile`
    3. Kibana: [`Estimated time = 8 minutes`]
        - In the Pipeline category select: Pipeline script from SCM
        - In the SCM: Git
        - In the Repository URL add: `https://github.com/ilegra/jovens-talentos.git`
        - In the Credentials add your credentials of Github;
        - In the Script Path add: `3-devops/antonio-azambuja/tema20/baking-elk/kibana/Jenkinsfile`

### Launch/Deploy

1. Baking Infrastructure: [`Estimated time = 2 minutes`]

- Description: Baking infrastructure in AWS, Security Groups - Rule Ingress and Egress, Subnets, VPC, etc. 

    - In the Pipeline category select: Pipeline script from SCM
    - In the SCM: Git
    - In the Repository URL add: `https://github.com/ilegra/jovens-talentos.git`
    - In the Credentials add your credentials of Github;
    - In the Script Path add: `3-devops/antonio-azambuja/tema20/baking-infrastructure/Jenkinsfile`

2. Deploy ELK: [`Estimated time = 6 minutes`]

- Description: Deploy with Kops for ELK Stack.

    - Execute following command for create key pair for cluster. For proper script operation: do not enter path to key pair. Your key pair will be generated in '~/.ssh/id_rsa.pub', and Kops for default use a same path!
    ```
    $ ssh-keygen
    ```
    - Run following script accessing folder `deploy-elk/`:
    
    PS: If you performed jobs of create ELK Stack and push your DockerHub, change yaml's of ES, Kibana and Logstash to get images in correct repository.
    ```
    $ ./create-cluster.sh
    ```
    - CLEAN-UP:
    ```
    $ ./delete-cluster.sh
    ```

3. Deploy Redis: [`Estimated time = 6 minutes`]

- Description: Deploy Redis cluster, Redis Master and Redis Slave. 

    - In the General category select: `Este build é parametrizado` and add of type `String Parameter`:
        - Name: `REDIS_MASTER_PASSWORD` | Default Value: `value` | Description: `REDIS_MASTER_PASSWORD`
        - Name: `REDIS_SLAVE_PASSWORD` | Default Value: `value` | Description: `REDIS_SLAVE_PASSWORD`
    - In the Pipeline category select: Pipeline script from SCM
    - In the SCM: Git
    - In the Repository URL add: `https://github.com/ilegra/jovens-talentos.git`
    - In the Credentials add your credentials of Github;
    - In the Script Path add: `3-devops/antonio-azambuja/tema20/deploy-redis/Jenkinsfile`

4. Deploy Calculator: [`Estimated time = 6 minutes`]

- Description: Deploy micro service Calculator in Golang. 

    - In the General category select: `Este build é parametrizado` and add of type `String Parameter`:
        - Name: `REDIS_MASTER_PASSWORD` | Default Value: `value` | Description: `REDIS_MASTER_PASSWORD`
        - Name: `REDIS_SLAVE_PASSWORD` | Default Value: `value` | Description: `REDIS_SLAVE_PASSWORD`
        - Name: `LOGSTASH_URL` | Default Value: `value` | Description: `LOGSTASH_URL`
    - In the Pipeline category select: Pipeline script from SCM
    - In the SCM: Git
    - In the Repository URL add: `https://github.com/ilegra/jovens-talentos.git`
    - In the Credentials add your credentials of Github;
    - In the Script Path add: `3-devops/antonio-azambuja/tema20/deploy-calc/Jenkinsfile`
    - For get logstash url, run following command:
    ```
    $ kubectl describe svc elk-logstash | grep "LoadBalancer Ingress:" | awk '{print $3;}'
    ```

## DONE

- Endpoints of Instances micro service Calculator:
```
SUM      - <ip-instance>:5000/calc/sum/{num1}/{num2} / POST-METHOD
SUB      - <ip-instance>:5000/calc/sub/{num1}/{num2} / POST-METHOD
MUL      - <ip-instance>:5000/calc/mul/{num1}/{num2} / POST-METHOD
DIV      - <ip-instance>:5000/calc/div/{num1}/{num2} / POST-METHOD
HISTORIC - <ip-instance>:5000/calc/historic / GET-METHOD
```

- For access Kibana get your URL, run following command:

Default port: `5601`
```
$ kubectl describe svc elk-logstash | grep "LoadBalancer Ingress:" | awk '{print $3;}'
```

Live Demo: https://youtu.be/p9ALyNexXMM

Thanks!