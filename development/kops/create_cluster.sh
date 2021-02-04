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

set -exo pipefail

BASEDIR=$(dirname "$0")
source ${BASEDIR}/set_k8s_versions.sh

kops get ig --name ${KOPS_CLUSTER_NAME} --state ${KOPS_STATE_STORE}| \
{ \
  read -r; while read -r line; \
  do \
    ig_name=`echo $line|awk '{print $1;}'`; \
    kops get ig --name ${KOPS_CLUSTER_NAME} $ig_name --state ${KOPS_STATE_STORE} -o yaml > existing_config.yaml; \
    instanc_profile="arn:aws:iam::051478615782:instance-profile/test-build-devstack-kopsAdminInstanceProfile-OD5ZLBSY5K7B"; \
    if [[ ${ig_name} == "nodes" ]]; then \
      instanc_profile="arn:aws:iam::051478615782:instance-profile/test-build-devstack-kopsNodesInstanceProfile-1UCR1AB6B0J3C"; \
    fi; \
    sed '/spec:/ a \ \ iam:\n \ \ \ profile: '"${instanc_profile}"'' existing_config.yaml > new_config.yaml; \
    cat new_config.yaml; \
    kops replace -f new_config.yaml --state ${KOPS_STATE_STORE} --name ${KOPS_CLUSTER_NAME};\
  done; \
}
kops update cluster --name ${KOPS_CLUSTER_NAME} --yes --lifecycle-overrides IAMRole=ExistsAndWarnIfChanges,IAMRolePolicy=ExistsAndWarnIfChanges,IAMInstanceProfileRole=ExistsAndWarnIfChanges
