# GCP Private Services Access

[![Build](https://github.com/DevSecOpsSamples/gcp-private-services-access/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/DevSecOpsSamples/gcp-private-services-access/actions/workflows/build.yml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=DevSecOpsSamples_gcp-private-services-access&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=DevSecOpsSamples_gcp-private-services-access) [![Lines of Code](https://sonarcloud.io/api/project_badges/measure?project=DevSecOpsSamples_gcp-private-services-access&metric=ncloc)](https://sonarcloud.io/summary/new_code?id=DevSecOpsSamples_gcp-private-services-access) [![Coverage](https://sonarcloud.io/api/project_badges/measure?project=DevSecOpsSamples_gcp-private-services-access&metric=coverage)](https://sonarcloud.io/summary/new_code?id=DevSecOpsSamples_gcp-private-services-access)

## Overview

Understand the Private Services Access for GKE and Memorystore in VPC.

## Objectives

You will learn the following: 

- Private networking with VPC peering on GKE
- Difference of networking mode between `DIRECT_PEERING` and `PRIVATE_SERVICE_ACCESS` in Memorystore
- Infrastructure provisioning for VPC private networking using Terraform

## Table of Contents

- [Step1: Create a VPC](#step1-create-a-vpc)
- [Step2: Create a GKE cluster](#step2-create-a-gke-cluster)
- [Step3: Create a Memorystore with DIRECT_PEERING mode](#step3-create-a-memorystore-with-direct_peering-mode)
- [Step4: Create a Memorystore with PRIVATE_SERVICE_ACCESS mode](#step4-create-a-memorystore-with-private_service_access-mode)
- [Step5: Deploy the redis-cli Pod for connectivity testing from GKE cluster to Memorystore instance](#step5-deploy-the-redis-cli-pod-for-connectivity-testing-from-gke-cluster-to-memorystore-instance)
- [Step6: Connectivity testing](#step6-connectivity-testing-from-pod-to-memorystore-instance)
- [Compare two VPC configurations](#compare-two-vpc-configurations)
- [Screenshots](#screenshots)
- [Cleanup](#cleanup)
- [References](#references)

### Installation

- [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli)
- [Install gsutil](https://cloud.google.com/storage/docs/gsutil_install#install)
- [Install kubectl and configure cluster access](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl)

## Create two workspaces and initializes working directories

Run `gradle tfinit` task to create workspaces and initializes working directories.

```bash
./gradlew tfinit
```

[build.gradle](build.gradle)

## Step1: Create a VPC

[01-vpc/main.tf](01-vpc/main.tf)

```bash
cd 01-vpc

terraform plan -var-file=vars/dev.tfvars
```

```bash
terraform apply -var-file=vars/dev.tfvars
```

```bash
gcloud compute addresses list --global --filter="purpose=VPC_PEERING"
```

```bash
NAME                             ADDRESS/RANGE    TYPE      PURPOSE      NETWORK              REGION  SUBNET  STATUS
google-managed-services-default  10.48.208.0/20   INTERNAL  VPC_PEERING  default                              RESERVED
managed-service-dev              172.20.128.0/20  INTERNAL  VPC_PEERING  gke-networktest-dev                  RESERVED
```

## Step2: Create a GKE cluster

[02-gke-cluster/main.tf](02-gke-cluster/main.tf)

```bash
cd ../02-gke-cluster

terraform plan -var-file=vars/dev.tfvars
```

```bash
terraform apply -var-file=vars/dev.tfvars
```

```bash
gcloud container clusters get-credentials gke-networktest-dev \
       --region=us-central1-a --project ${PROJECT_ID}
```

## Step3: Create a Memorystore with DIRECT_PEERING mode

[03-memorystore-direct-peering/main.tf](03-memorystore-direct-peering/main.tf)

```bash
cd ../03-memorystore-direct-peering

terraform plan -var-file=vars/dev.tfvars
```

```bash
terraform apply -var-file=vars/dev.tfvars
```

Confirm that routing table and VPC peering on https://console.cloud.google.com/networking/networks/details/gke-networktest-dev?pageTab=ROUTES.

Three tasks will be done automatically when creating with 'DIRECT_PEERING' mode:

1. Assign a CIDR with unused IP range
2. Create a VPC peering
3. Add a routing table

    | Name                           | Description             | Destination IP range | Priority | Next hop|
    |--------------------------------|-------------------|---------------------------------|-----------|-----------|
    | peering-route-8e5214d760dadaf6 | Auto generated route via peering [redis-peer-207810071261]. | 10.30.40.96/29 | 0 | Network peering servicenetworking-googleapis-com	|

## Step4: Create a Memorystore with PRIVATE_SERVICE_ACCESS mode

[04-memorystore-psa/main.tf](04-memorystore-psa/main.tf)

```bash
cd ../04-memorystore-psa

terraform plan -var-file=vars/dev.tfvars
```

```bash
terraform apply -var-file=vars/dev.tfvars
```

## Step5: Deploy the redis-cli Pod for connectivity testing from GKE cluster to Memorystore instance

[05-k8s-redis-cli/redis-stack-template.yaml](05-k8s-redis-cli/redis-stack-template.yaml)

```bash
cd ../05-k8s-redis-cli

echo "PROJECT_ID: ${PROJECT_ID}"

docker build -t redis-stack . --platform linux/amd64
docker tag redis-stack:latest gcr.io/${PROJECT_ID}/redis-stack:latest
docker push gcr.io/${PROJECT_ID}/redis-stack:latest

gcloud container clusters get-credentials gke-network-test-dev \
       --region=us-central1-a --project ${PROJECT_ID}

sed -e "s|<project-id>|${PROJECT_ID}|g" redis-stack-template.yaml > redis-stack.yaml
cat redis-stack.yaml
```

```bash
kubectl create namespace redis

kubectl apply -f redis-stack.yaml -n redis
```

## Step6: Connectivity testing from Pod to Memorystore instance

Confirm that connectivity from Pod to Memorystore instance with redis-cli:

```bash
DP_REDIS_HOST=$(gcloud redis instances describe redis-directpeering-dev --region=us-central1 | grep host | cut -d' ' -f2)
echo $DP_REDIS_HOST

PSA_REDIS_HOST=$(gcloud redis instances describe redis-psa-dev --region=us-central1 | grep host | cut -d' ' -f2)
echo $PSA_REDIS_HOST
```

Run the command in Pod:

```bash
redis-cli -h 172.19.128.4 -p 6379 PING
```

```bash
root@redis-stack-8565f88fdf-n4tll:/# redis-cli -h 172.19.128.4 -p 6379 PING
PONG
```

### Compare two VPC configurations

If you want to compare VPC configurations, create 2 VPCs with the 'dev' and 'stg' stages in the same GCP project like the following:

| Mode                   | Resouce      | Resouce Name            | Stage |
|------------------------|--------------|-------------------------|-------|
| DIRECT_PEERING         | VPC          | gke-networktest-dev     | dev   |
| DIRECT_PEERING         | GKE          | gke-networktest-dev     | dev   |
| DIRECT_PEERING         | Memorystore  | redis-directpeering-dev | dev   |
| PRIVATE_SERVICE_ACCESS | VPC          | gke-networktest-stg     | stg   |
| PRIVATE_SERVICE_ACCESS | GKE          | gke-networktest-stg     | stg   |
| PRIVATE_SERVICE_ACCESS | Memorystore  | redis-psa-stg           | stg   |

```bash
terraform -chdir='01-vpc' workspace select dev
terraform -chdir='02-gke-cluster' workspace select dev
terraform -chdir='03-memorystore-direct-peering' workspace select dev

cd 01-vpc
# 172.19.0.0/16
terraform apply -var-file=vars/dev.tfvars

cd ../02-gke-cluster
terraform apply -var-file=vars/dev.tfvars

gcloud container clusters get-credentials gke-networktest-dev \
       --region=us-central1-a --project ${PROJECT_ID}

cd ../03-memorystore-direct-peering
terraform apply -var-file=vars/dev.tfvars
```

Update the b-class variable from `172.19` to `172.20` in [01-vpc/main.tf](01-vpc/main.tf):

```bash
locals {
  vpc-name-without-stage = "gke-networktest"
  # b-class = "172.19"
  b-class = "172.20"
}
```

```bash
terraform -chdir='01-vpc' workspace select stg
terraform -chdir='02-gke-cluster' workspace select stg
terraform -chdir='04-memorystore-psa' workspace select stg

cd ../01-vpc
# 172.20.0.0/16
terraform apply -var-file=vars/stg.tfvars

cd ../02-gke-cluster
terraform apply -var-file=vars/stg.tfvars

gcloud container clusters get-credentials gke-networktest-stg \
       --region=us-central1-a --project ${PROJECT_ID}

cd ../04-memorystore-psa
terraform apply -var-file=vars/stg.tfvars
```

```bash
DP_REDIS_HOST=$(gcloud redis instances describe redis-directpeering-dev --region=us-central1 | grep host | cut -d' ' -f2)
echo $DP_REDIS_HOST

PSA_REDIS_HOST=$(gcloud redis instances describe redis-psa-stg --region=us-central1 | grep host | cut -d' ' -f2)
echo $PSA_REDIS_HOST
```

```bash
# IP range of direct peering mode will be created with 10.xx
10.233.55.3
172.19.128.3
```

```bash
# in dev cluster
redis-cli -h 10.233.55.3 -p 6379 PING

# in stg cluster
redis-cli -h 172.19.128.3 -p 6379 PING
```

### Screenshots

- DIRECT_PEERING

    ![Services](./screenshots/01-direct-peering-routes.png?raw=true)

    ![Services](./screenshots/02-direct-peering-vpc-peering.png?raw=true)

    ![Services](./screenshots/03-direct-peering-ip-ranges.png?raw=true)

    ![Services](./screenshots/04-direct-peering-private-connections.png?raw=true)

- PRIVATE_SERVICE_ACCESS

    ![Services](./screenshots/11-psa-routes.png?raw=true)

    ![Services](./screenshots/12-psa-vpc-peering.png?raw=true)

    ![Services](./screenshots/13-psa-ip-ranges.png?raw=true)

    ![Services](./screenshots/14-psa-private-connections.png?raw=true)

### Cleanup

```bash
terraform -chdir='01-vpc' workspace select dev
terraform -chdir='02-gke-cluster' workspace select dev
terraform -chdir='03-memorystore-direct-peering' workspace select dev
terraform -chdir='04-memorystore-psa' workspace select dev

terraform -chdir='04-memorystore-psa' destroy -var-file=vars/dev.tfvars
terraform -chdir='03-memorystore-direct-peering' destroy -var-file=vars/dev.tfvars
terraform -chdir='02-gke-cluster' destroy -var-file=vars/dev.tfvars
terraform -chdir='01-vpc' destroy -var-file=vars/dev.tfvars
```

```bash
terraform -chdir='01-vpc' workspace select stg
terraform -chdir='02-gke-cluster' workspace select stg
terraform -chdir='03-memorystore-direct-peering' workspace select stg
terraform -chdir='04-memorystore-psa' workspace select stg

terraform -chdir='04-memorystore-psa' destroy -var-file=vars/stg.tfvars
terraform -chdir='03-memorystore-direct-peering' destroy -var-file=vars/stg.tfvars
terraform -chdir='02-gke-cluster' destroy -var-file=vars/stg.tfvars
terraform -chdir='01-vpc' destroy -var-file=vars/stg.tfvars
```

```bash
./gradlew clean
```

### References

- GCP
    - [Virtual Private Cloud > Documentation > Guides > Configure private services access](https://cloud.google.com/vpc/docs/configure-private-services-access)
    - [Memorystore > Memorystore for Redis > Guides > Networking](https://cloud.google.com/memorystore/docs/redis/networking)
    - https://cloud.google.com/memorystore/docs/redis/connect-redis-instance-gke

- Terraform
    - [Private Service Connect](https://registry.terraform.io/modules/terraform-google-modules/network/google/latest/submodules/private-service-connect)
    - [google_compute_global_address](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address)
    - [google_service_networking_connection](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_networking_connection)
    - [container_cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster)
    - [Project API Activation](https://registry.terraform.io/modules/terraform-google-modules/project-factory/google/latest/submodules/project_services)
