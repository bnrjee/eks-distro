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
source ${BASEDIR}/set_k8s_versions.sh

kops get ig --name ${KOPS_CLUSTER_NAME} --state ${KOPS_STATE_STORE}| \
{ \
  read -r; while read -r line; \
  do \
    ig_name=`echo $line|awk '{print $1;}'`; \
    kops get ig --name ${KOPS_CLUSTER_NAME} $ig_name --state ${KOPS_STATE_STORE} -o yaml > existing_config.yaml; \
    sed '/spec:/ a \ \ iam:\n \ \ \ profile: arn:aws:iam::051478615782:instance-profile/test-build-devstack-kopsInstanceProfile-G4D5MX8W6YMF' existing_config.yaml > new_config.yaml; \
    cat new_config.yaml; \
    kops replace -f new_config.yaml --state --state ${KOPS_STATE_STORE} --name ${KOPS_CLUSTER_NAME};\
  done; \
}
kops update cluster --name ${KOPS_CLUSTER_NAME} --yes --lifecycle-overrides IAMRole=ExistsAndWarnIfChanges,IAMRolePolicy=ExistsAndWarnIfChanges,IAMInstanceProfileRole=ExistsAndWarnIfChanges
kops rolling-update cluster ${KOPS_CLUSTER_NAME} --yes
