# Terraform for GKE Workload Identity


https://cloud.google.com/sdk/docs/downloads-docker

```bash
docker pull gcr.io/google.com/cloudsdktool/google-cloud-cli:latest
docker run --rm gcr.io/google.com/cloudsdktool/google-cloud-cli:latest gcloud version
docker run --rm gcr.io/google.com/cloudsdktool/google-cloud-cli:372.0.0 gcloud version



Google Cloud SDK 412.0.0
alpha 2022.12.09
app-engine-go 1.9.72
app-engine-java 2.0.10
app-engine-python 1.9.101
app-engine-python-extras 1.9.97
beta 2022.12.09
bigtable
bq 2.0.83
bundled-python3-unix 3.9.12
cbt 0.13.0
cloud-datastore-emulator 2.3.0
cloud-firestore-emulator 1.15.1
cloud-spanner-emulator 1.4.8
core 2022.12.09
datalab 20190610
gcloud-crc32c 1.0.0
gke-gcloud-auth-plugin 0.4.0
gsutil 5.17
kpt 1.0.0-beta.19
local-extract 1.5.5
pubsub-emulator 0.7.2

docker run -ti --name gcloud-config gcr.io/google.com/cloudsdktool/google-cloud-cli gcloud auth login

```

https://cloud.google.com/memorystore/docs/redis/troubleshoot-issues

https://cloud.google.com/memorystore/docs/redis/establish-connection

```bash
│ Error: Error creating Instance: googleapi: Error 400: Google private service access is not enabled. Enable private service access and try again.
│ com.google.apps.framework.request.StatusException: <eye3 title='FAILED_PRECONDITION'/> generic::FAILED_PRECONDITION: Google private service access is not enabled. Enable private service access and try again.
│ 
│   with google_redis_instance.this[0],
│   on main.tf line 10, in resource "google_redis_instance" "this":
│   10: resource "google_redis_instance" "this" {
```

https://console.cloud.google.com/networking/networks/details/gke-network-test?pageTab=PRIVATE_SERVICE_CONNECTION