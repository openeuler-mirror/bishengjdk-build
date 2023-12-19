#!/bin/bash
# Copyright Huawei Technologies Co., Ltd. 2022. All rights reserved.

export BISHENGJDK_8_BUILD_VARIANT="jdk8"
export BISHENGJDK_11_BUILD_VARIANT="jdk11"
export BISHENGJDK_17_BUILD_VARIANT="jdk17"
export BISHENGJDK_21_BUILD_VARIANT="jdk21"
export BISHENGJDK_RISCV_BUILD_VARIANT="riscv"

export BISHENGJDK_DEFAULT_SOURCE_DIR="${ROOT_DIR}/src"
export BISHENGJDK_DEFAULT_OUTPUT_DIR="${ROOT_DIR}/output"
export BISHENGJDK_DEFAULT_CONFIG_DIR="${ROOT_DIR}/config"
export BISHENGJDK_DEFAULT_TEMP_DIR="${ROOT_DIR}/tmp"
export BISHENGJDK_DEFAULT_TOOLS_DIR="${ROOT_DIR}/tools"
export BISHENGJDK_DEFAULT_CONFIG_BUILD_CONFIG_FILE="${BISHENGJDK_DEFAULT_CONFIG_DIR}/config.txt"

export BISHENGJDK_DEFAULT_VENDOR_NAME="BiSheng"
export BISHENGJDK_DEFAULT_BASE_REPO_URL="https://gitee.com/openeuler/"

declare -A BISHENGJDK_REPO_DEFAULT_URL
for i in 8 11 17 21 RISCV
do
  bishengjdkBuildVarient=BISHENGJDK_${i}_BUILD_VARIANT
  bishengjdkDefaultRepoURL="${BISHENGJDK_DEFAULT_BASE_REPO_URL}bishengjdk-$(echo ${i} | awk '{print tolower($0)}')/"
  BISHENGJDK_REPO_DEFAULT_URL[${!bishengjdkBuildVarient}]=${bishengjdkDefaultRepoURL}
done
export BISHENGJDK_REPO_DEFAULT_URL