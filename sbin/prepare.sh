#!/bin/bash
# Copyright Huawei Technologies Co., Ltd. 2022. All rights reserved.

################################################################################
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

set -e

source "${ROOT_DIR}/sbin/common/constants.sh"
source "${ROOT_DIR}/sbin/common/common.sh"

BUILD_JDK_RESOURCE_DIR="${ROOT_DIR}/resources"

BUILD_JDK_17_DEFAULT_AARCH64_BOOT_JDK_URL="https://mirrors.huaweicloud.com/kunpeng/archive/compiler/bisheng_jdk/bisheng-jdk-17.0.1-linux-aarch64.tar.gz"
BUILD_JDK_17_DEFAULT_X86_64_BOOT_JDK_URL="https://mirrors.huaweicloud.com/kunpeng/archive/compiler/bisheng_jdk/bisheng-jdk-17.0.1-linux-x64.tar.gz"

BUILD_JDK_21_DEFAULT_AARCH64_BOOT_JDK_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.1%2B12/OpenJDK21U-jdk_aarch64_linux_hotspot_21.0.1_12.tar.gz"
BUILD_JDK_21_DEFAULT_X86_64_BOOT_JDK_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.1%2B12/OpenJDK21U-jdk_x64_linux_hotspot_21.0.1_12.tar.gz"

JTREG_5_DOWNLOAD_URL="https://ci.adoptopenjdk.net/view/Dependencies/job/dependency_pipeline/lastSuccessfulBuild/artifact/jtreg/jtreg5.1-b01.tar.gz"
JTREG_6_DOWNLOAD_URL="https://ci.adoptopenjdk.net/view/Dependencies/job/dependency_pipeline/lastSuccessfulBuild/artifact/jtreg/jtreg-6+1.tar.gz"


function DownloadFile () {
  local requestURL=$1
  local targetName=
  if [[ $# -eq 2 ]]; then
    targetName="$2"
  fi

  if [[ -z "$targetName" ]]; then
    PrintInfo "Downloading from ${requestURL}"
    curl -k -L "${requestURL}"
  else
    PrintInfo "Downloading ${targetName} from ${requestURL}"
    curl -k -L -o "${targetName}" "${requestURL}"
  fi
}

function CreateDirs () {
  mkdir -p "${BUILD_JDK_RESOURCE_DIR}"
  mkdir -p "${BISHENGJDK_DEFAULT_TEMP_DIR}"
}

function InstallJDKBuildTools () {
  local dependencies=(autoconf \
                      gcc-c++ \
                      libXtst-devel libXt-devel libXrender-devel libXrandr-devel libXi-devel \
                      cups-devel \
                      freetype-devel \
                      alsa-lib-devel \
                      unzip \
                      fontconfig-devel)
  if [[ -z "${BUILD_CONFIG[BOOT_JDK]}" ]]; then 
    if [[ "${BUILD_CONFIG[BUILD_VARIANT]}" = "${BISHENGJDK_8_BUILD_VARIANT}" ]]; then
      dependencies+=(java-1.8.0-openjdk-devel)
    elif [[ "${BUILD_CONFIG[BUILD_VARIANT]}" = "${BISHENGJDK_11_BUILD_VARIANT}" ]]; then
      dependencies+=(java-11-openjdk-devel)
    elif [[ "${BUILD_CONFIG[BUILD_VARIANT]}" = "${BISHENGJDK_17_BUILD_VARIANT}" ]]; then
      cd "${ROOT_DIR}/resources"
      if [[ "${BUILD_CONFIG[ARCH]}" = "aarch64" ]]; then
        DownloadFile "${BUILD_JDK_17_DEFAULT_AARCH64_BOOT_JDK_URL}" bishengjdk-17.tar.gz
      else
        DownloadFile "${BUILD_JDK_17_DEFAULT_X86_64_BOOT_JDK_URL}" bishengjdk-17.tar.gz
      fi
      tar -xf bishengjdk-17.tar.gz
      BUILD_CONFIG[BOOT_JDK]="${BUILD_JDK_RESOURCE_DIR}/bisheng-jdk-17.0.1"
    elif [[ "${BUILD_CONFIG[BUILD_VARIANT]}" = "${BISHENGJDK_21_BUILD_VARIANT}" ]]; then
      cd "${ROOT_DIR}/resources"
      if [[ "${BUILD_CONFIG[ARCH]}" = "aarch64" ]]; then
        DownloadFile "${BUILD_JDK_21_DEFAULT_AARCH64_BOOT_JDK_URL}" bishengjdk-21.tar.gz
      else
        DownloadFile "${BUILD_JDK_21_DEFAULT_X86_64_BOOT_JDK_URL}" bishengjdk-21.tar.gz
      fi
      tar -xf bishengjdk-21.tar.gz
      BUILD_CONFIG[BOOT_JDK]="${BUILD_JDK_RESOURCE_DIR}/jdk-21.0.1+12"
    fi
  fi
  if [[ "${BUILD_CONFIG[ARCH]}" = "aarch64" ]]; then
    dependencies+=(openssl-devel)
  fi
  if [[ "${BUILD_CONFIG[BUILD_TYPE]}" = "ci" ]]; then
    for dep in ${dependencies[@]}; do
      sudo yum -y install ${dep}
    done
  else
    # Currently, we assume users have installed the tools to build jdk.
    # Maybe something can be done to do it better.
    PrintInfo "Make sure you have installed these tools: ${dependencies[*]}"
  fi
}

function InstallJtregTestTools () {
  cd "${BISHENGJDK_DEFAULT_TOOLS_DIR}"
  local jtregPath=$(echo "${BISHENGJDK_DEFAULT_TOOLS_DIR}"/jtreg*6*.tar.gz)
  if [[ "${BUILD_CONFIG[MAJOR_NUMBER]}" -eq 8 ]] ; then
    jtregPath=$(echo "${BISHENGJDK_DEFAULT_TOOLS_DIR}"/jtreg*5*.tar.gz)
  fi
  cp "$jtregPath" "${BUILD_JDK_RESOURCE_DIR}/jtreg.tar.gz"
  cd "${BUILD_JDK_RESOURCE_DIR}"
  tar xf jtreg.tar.gz
  cd jtreg
  BUILD_CONFIG[JTREG_HOME]="$PWD"
  PrintInfo "Jtreg is ready"
  echo $(./bin/jtreg -version)
}

function PrepareEnvironment () {
  source "$BISHENGJDK_DEFAULT_CONFIG_BUILD_CONFIG_FILE"

  CreateDirs
  InstallJDKBuildTools
  if [[ "${BUILD_CONFIG[BUILD_TYPE]}" = "ci" ]]; then
    InstallJtregTestTools
    SetJtregTestCases
  fi
  ArchiveBuildConfig
}
