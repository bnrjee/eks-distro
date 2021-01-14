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


set -x
set -o errexit
set -o nounset
set -o pipefail

if [ -z "$1" ]; then
  echo "arg 1, RELEASE BRANCH arg is missing"
  exit 1
fi

if [ -z "$2" ]; then
  echo "arg 2, RELEASE arg is missing"
  exit 1
fi

if [ -z "$3" ]; then
  echo "arg 3, ARTIFACT_BUCKET arg is missing"
  exit 1
fi

RELEASE_BRANCH="$1"
RELEASE="$2"
ARTIFACT_BUCKET="$3"
PROJECT="$4"
DEST_DIR=kubernetes-${RELEASE_BRANCH}/releases/${RELEASE}/artifacts

if [ $PROJECT = "kubernetes/kubernetes" ]; then
  SOURCE_DIR=projects/${PROJECT}/_output/${RELEASE_BRANCH}
  GIT_TAG=$(cat projects/${PROJECT}/${RELEASE_BRANCH}/GIT_TAG)
else
  SOURCE_DIR=projects/${PROJECT}/_output/tar/
  GIT_TAG=$(cat projects/${PROJECT}/GIT_TAG)
fi
REPO="$(cut -d '/' -f2 <<< ${PROJECT})"
ARTIFACT_DIR=${DEST_DIR}/${REPO}/${GIT_TAG}
mkdir -p $ARTIFACT_DIR || true
cp -r $SOURCE_DIR/* $ARTIFACT_DIR || true

aws s3 sync $DEST_DIR s3://${ARTIFACT_BUCKET}/${DEST_DIR} --acl public-read || true
