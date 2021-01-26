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
export AWS_DEFAULT_PROFILE=default
export AWS_PROFILE=default
assume_test_role_output=`aws sts assume-role --role-arn $TEST_ROLE_ARN --role-session-name test-role-session`
export AWS_ACCESS_KEY_ID=`echo $assume_test_role_output|jq -r .Credentials.AccessKeyId`
export AWS_SECRET_ACCESS_KEY=`echo $assume_test_role_output|jq -r .Credentials.SecretAccessKey`
export AWS_SESSION_TOKEN=`echo $assume_test_role_output|jq -r .Credentials.SessionToken`
unset AWS_DEFAULT_PROFILE
unset AWS_PROFILE
unset AWS_SDK_LOAD_CONFIG
aws sts get-caller-identity
BASEDIR=$(dirname "$0")
source ${BASEDIR}/set_k8s_versions.sh

kops update cluster --name ${KOPS_CLUSTER_NAME} --yes
