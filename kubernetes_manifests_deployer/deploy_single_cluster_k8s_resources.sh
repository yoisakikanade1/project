#!/bin/bash

# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Script parameters
PROJECT_ID=$1
RESOURCE_NAME_SUFFIX=$2
K8S_MANIFESTS_DIR=$3

CLUSTER_CONTEXT_TOKYO=gke_${PROJECT_ID}_asia-northeast1_my-cluster-tokyo${RESOURCE_NAME_SUFFIX}
CLUSTER_CONTEXT_CONFIG=gke_${PROJECT_ID}_asia-northeast3_my-cluster-config${RESOURCE_NAME_SUFFIX}
CLUSTER_CONTEXT_SEOUL=gke_${PROJECT_ID}_asia-northeast3_my-cluster-seoul${RESOURCE_NAME_SUFFIX}

# Connect to the 3 clusters that we just created.
gcloud container clusters get-credentials "my-cluster-tokyo${RESOURCE_NAME_SUFFIX}" \
  --project "${PROJECT_ID}" \
  --region asia-northeast1
gcloud container clusters get-credentials "my-cluster-seoul${RESOURCE_NAME_SUFFIX}" \
  --project "${PROJECT_ID}" \
  --region asia-northeast3
gcloud container clusters get-credentials "my-cluster-config${RESOURCE_NAME_SUFFIX}" \
  --project "${PROJECT_ID}" \
  --region asia-northeast3

app_namespaces=(adservice cartservice checkoutservice currencyservice emailservice frontend paymentservice productcatalogservice recommendationservice shippingservice)

# Create namespaces.
# Some Namespaces (especially in my-cluster-config) will be unused.
kubectl --context="${CLUSTER_CONTEXT_SEOUL}" \
  apply -f "${K8S_MANIFESTS_DIR}/namespaces.yaml"
kubectl --context="${CLUSTER_CONTEXT_TOKYO}" \
  apply -f "${K8S_MANIFESTS_DIR}/namespaces.yaml"
kubectl --context="${CLUSTER_CONTEXT_CONFIG}" \
  apply -f "${K8S_MANIFESTS_DIR}/namespaces.yaml"

# Deploy most of the microservices.
for namespace in "${app_namespaces[@]}";
do
  kubectl --context="${CLUSTER_CONTEXT_SEOUL}" \
    apply -f "${K8S_MANIFESTS_DIR}/${namespace}/"
  kubectl --context="${CLUSTER_CONTEXT_TOKYO}" \
    apply -f "${K8S_MANIFESTS_DIR}/${namespace}/"
done
