#!/usr/bin/env bash
# Copyright 2020 Amazon.com Inc. or its affiliates. All Rights Reserved.
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

set -eo pipefail

BASEDIR=$(dirname "$0")
source ${BASEDIR}/set_environment.sh
$PREFLIGHT_CHECK_PASSED || exit 1

echo "Download sonobuoy"
if [ "$(uname)" == "Darwin" ]
then
  SONOBUOY=https://github.com/vmware-tanzu/sonobuoy/releases/download/v0.19.0/sonobuoy_0.19.0_darwin_amd64.tar.gz
else
  SONOBUOY=https://github.com/vmware-tanzu/sonobuoy/releases/download/v0.19.0/sonobuoy_0.19.0_linux_386.tar.gz
fi
CONFORMANCE_IMAGE=k8s.gcr.io/conformance:${KUBERNETES_VERSION}
wget -qO- ${SONOBUOY} |tar -xz sonobuoy
chmod 755 sonobuoy
echo "Making sure cluster ${KOPS_CLUSTER_NAME} is ready to run sonobuoy"
while ! ./sonobuoy run --mode=certified-conformance --wait --mode quick --kube-conformance-image ${CONFORMANCE_IMAGE}
do
  ./sonobuoy delete --all --wait||true
  sleep 5
  COUNT=$(expr $COUNT + 1)
  if [ $COUNT -gt 40 ]
  then
    echo "Failed to run sonobuoy"
    exit 1
  fi
  echo 'Waiting for the cluster to be ready...'
done
./sonobuoy delete --all --wait||true
echo "Testing cluster ${KOPS_CLUSTER_NAME}"
./sonobuoy run --mode=certified-conformance --wait --kube-conformance-image ${CONFORMANCE_IMAGE}
results=$(./sonobuoy retrieve)
mv $results "./${KOPS_CLUSTER_NAME}/$results"
results="./${KOPS_CLUSTER_NAME}/$results"
mkdir ./${KOPS_CLUSTER_NAME}/results
tar xzf $results -C ./${KOPS_CLUSTER_NAME}/results
if [ -w /logs/artifacts ]
then
  cp ./${KOPS_CLUSTER_NAME}/results/plugins/e2e/results/global/junit_01.xml /logs/artifacts
fi
./sonobuoy e2e ${results}
./sonobuoy e2e ${results} | grep 'failed tests: 0' >/dev/null
