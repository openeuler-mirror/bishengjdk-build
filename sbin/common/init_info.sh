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

OS_NAME=
OS_ARCHITECTURE=$(uname -m)

BUILD_JDK_VARIANT=
BUILD_JDK_MAJOR=
BUILD_JDK_MINOR=
BUILD_JDK_BUILD_NUMBER=
BUILD_JDK_USER_SPECIFIED_CONFIGURE_ARGS=
BUILD_JDK_CREATE_JRE_IMAGE=false
BUILD_JDK_BOOT_JDK=
BUILD_JDK_USER_SPECIFIED_MAKE_ARGS=
BUILD_JDK_JVM_VARIANT=server
BUILD_JDK_BUILD_TYPE=release
BUILD_JDK_JDK_PATH=
BUILD_JDK_JRE_PATH=

JREG_TEST_ABORT_RETEST_MAX_NUMBER=50

BISHENGJDK_REPO_URL=
BISHENGJDK_REPO_BRANCH=
BISHENGJDK_REPO_TAG=
BISHENGJDK_VENDOR_NAME=$BISHENGJDK_DEFAULT_VENDOR_NAME

BISHENGJDK_SOURCE_DIR=
BISHENGJDK_OUTPUT_DIR=$BISHENGJDK_DEFAULT_OUTPUT_DIR
BISHENGJDK_SOURCE_ARCHIVE_PREFIX=srcArchive

# please keep the args in lexicographic order
function ParseArguements () {
  local longArgs=(abort-retest-number: \
                  branch: boot-jdk-dir: build-number: build-type: build-variant: \
                  configure-args: create-jre-image \
                  destination: \
                  help \
                  jvm-variant: \
                  make-args: \
                  repository: \
                  source: \
                  tag: \
                  update-version: \
                  )
  local args=$(getopt -a -o b:B:c:d:hr:s:t:u: \
                          -l $(echo "${longArgs[*]}" | tr ' ' ',') -- "$@")
  if [ $? -ne 0 ]; then
    echo "[Usage]: invalid arguments !"
    exit 1
  fi

  eval set -- "${args}"
  while true; do
    opt=$1;
    shift;
    case "$opt" in

      --abort-retest-number)
        JREG_TEST_ABORT_RETEST_MAX_NUMBER="$1"; shift;;

      --boot-jdk-dir)
        BUILD_JDK_BOOT_JDK="$1"; shift;;

      -b | --branch)
        BISHENGJDK_REPO_BRANCH="$1"; shift;;

      -B | --build-number)
        BUILD_JDK_BUILD_NUMBER="$1"; shift;;
      
      --build-type)
        BUILD_JDK_BUILD_TYPE="$1"; shift;;

      --build-variant)
        case "$1" in
          jdk8|jdk11|jdk17|riscv)
            BUILD_JDK_VARIANT="$1"; shift;;
          *)
            PrintError "Only jdk8|jdk11|jdk17|riscv is supported!"
          esac;;
      -c | --configure-args)
        BUILD_JDK_USER_SPECIFIED_CONFIGURE_ARGS="$1"; shift;;

      --create-jre-image)
        BUILD_JDK_CREATE_JRE_IMAGE=true;;

      -d | --destination)
        BISHENGJDK_OUTPUT_DIR="$1"; shift;;

      -h | --help)
        man ${ROOT_DIR}/build.man
        exit 0;;

      --jvm-variant)
        BUILD_JDK_JVM_VARIANT="$1"; shift;;
      
      --make-args)
        BUILD_JDK_USER_SPECIFIED_MAKE_ARGS=$1; shift;;

      -r | --repository)
        BISHENGJDK_REPO_URL="$1"; shift;;

      -s | --source)
        BISHENGJDK_SOURCE_DIR="$1"; shift;;

      -t | --tag)
        BISHENGJDK_REPO_TAG="$1"; shift;;

      -u | --update-version)
        BUILD_JDK_MINOR="$1"; shift;;

      --jvm-variant)
        BUILD_JDK_JVM_VARIANT="$1"; shift;;

      --)
        break;;
    esac
  done
}

function BasicConfig () {
  # Get OS name, now linux is only supported system.
  # Determine OS full system version
  local osName=$(uname -s)

  if [[ $osName != "Linux" ]]; then
    PrintError 'The scipts now only supports building and testing on Linux.'
  fi

  local osSysVersion=$(uname -sr)
  # Linux distribs add more useful distrib in the single line file /etc/system-release,
  # or property file /etc/os-release
  if [[ -f "/etc/system-release" ]]; then
    OS_NAME=$(cat /etc/system-release | tr -d '"')
  elif [[ -f "/etc/os-release" ]]; then
    if grep "^NAME=" /etc/os-release; then
      local osName=$(grep "^NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
    fi
    if grep "^VERSION=" /etc/os-release; then
      local osVersion=$(grep "^VERSION=" /etc/os-release | cut -d= -f2 | tr -d '"')
    fi
    OS_NAME="${osName} ${osVersion}"
  fi

  # determine src code
  if [[ "$BISHENGJDK_SOURCE_DIR" != "$BISHENGJDK_DEFAULT_SOURCE_DIR" ]]; then
    if [[ -d "$BISHENGJDK_DEFAULT_SOURCE_DIR" ]]; then
      PrintInfo "Archiving $BISHENGJDK_DEFAULT_SOURCE_DIR"
      local date=$(date -u +%Y-%m-%d-%H%M)
      local srcArchiveTargetName="${BISHENGJDK_SOURCE_ARCHIVE_PREFIX}_${date}"
      CreateTarArchive "$(basename $BISHENGJDK_DEFAULT_SOURCE_DIR)" "$srcArchiveTargetName"
      mkdir -p "$BISHENGJDK_DEFAULT_TEMP_DIR"
      mv "${srcArchiveTargetName}.tar.gz" "$BISHENGJDK_DEFAULT_TEMP_DIR"
      PrintInfo "Original source is archived at ${BISHENGJDK_DEFAULT_TEMP_DIR}/${srcArchiveTargetName}"
      rm -rf src || true
    fi
    if [[ -n "$BISHENGJDK_SOURCE_DIR" ]]; then
      PrintInfo "Moving $BISHENGJDK_SOURCE_DIR to $BISHENGJDK_DEFAULT_SOURCE_DIR"
      mkdir "$BISHENGJDK_DEFAULT_SOURCE_DIR"
      cp -r "$BISHENGJDK_SOURCE_DIR"/. "$BISHENGJDK_DEFAULT_SOURCE_DIR"
      # make file privilege right
      chmod -R a+r "$BISHENGJDK_DEFAULT_SOURCE_DIR"
    fi
  fi

  # Default umask of OpenEuler system is 0077.
  # 0022 is expected before download the source code.
  umask 0022

  BISHENGJDK_SOURCE_DIR=$BISHENGJDK_DEFAULT_SOURCE_DIR
  if [[ ! -f "$BISHENGJDK_SOURCE_DIR/configure" ]]; then
    local repoBranch=$BISHENGJDK_REPO_BRANCH
    # user specified the tag to build
    if [[ -n "$BISHENGJDK_REPO_TAG" ]]; then
      repoBranch=$BISHENGJDK_REPO_TAG
    fi

    if [[ -n "$BISHENGJDK_REPO_URL" ]]; then
       :
    elif [[ -n "$BUILD_JDK_VARIANT" ]]; then
      BISHENGJDK_REPO_URL=${BISHENGJDK_REPO_DEFAULT_URL[$BUILD_JDK_VARIANT]}
      if [[ "$BUILD_JDK_BUILD_TYPE" = "release" && -z "$repoBranch"  ]]; then
        PrintInfo "Getting lastest tags ..."
        repoBranch=$(GetLastestTag "$BISHENGJDK_REPO_URL")
        [[ -z "$repoBranch" ]] && PrintError "Getting lastest tag fails"
        PrintInfo "Finish getting lastest tags"
      fi
    else
      PrintError "You must at least specify the bishengjdk or repository URL!"
    fi

    if [[ -z "$repoBranch" ]]; then
      repoBranch=master
    fi
    git clone "$BISHENGJDK_REPO_URL" --branch "$repoBranch" --depth 1 "$BISHENGJDK_SOURCE_DIR"
  fi

  # determine version of jdk
  if [[ -z "$BUILD_JDK_MAJOR" ]]; then
    if [[ -f "$BISHENGJDK_SOURCE_DIR/version.txt" ]]; then
      BUILD_JDK_MAJOR=$(cat "$BISHENGJDK_SOURCE_DIR/version.txt" | cut -d. -f1)
    else
      PrintError 'You must specify the core version of jdk!'
    fi
  fi
  if [[ -z "$BUILD_JDK_MINOR" ]]; then
    if [[ -f "$BISHENGJDK_SOURCE_DIR/version.txt" ]]; then
      BUILD_JDK_MINOR=$(cat "$BISHENGJDK_SOURCE_DIR/version.txt" | cut -d. -f3)
      if [[ "$BUILD_JDK_VARIANT" = "$BISHENGJDK_8_BUILD_VARIANT" ]]; then
        BUILD_JDK_MINOR=$(cat "$BISHENGJDK_SOURCE_DIR/version.txt" | cut -d. -f2)
      fi
    else
      PrintError 'You must specify the feature version of jdk!'
    fi
  fi

  if [[ -z "$BUILD_JDK_BUILD_NUMBER" ]]; then
    if [[ -f "$BISHENGJDK_SOURCE_DIR/version.txt" ]]; then
      BUILD_JDK_BUILD_NUMBER=$(cat "$BISHENGJDK_SOURCE_DIR/version.txt" | cut -d. -f5)
      if [[ "$BUILD_JDK_VARIANT" = "$BISHENGJDK_8_BUILD_VARIANT" ]]; then
        BUILD_JDK_BUILD_NUMBER=$(cat "$BISHENGJDK_SOURCE_DIR/version.txt" | cut -d. -f3)
      fi
    else
      PrintError 'You must specify the build number of jdk!'
    fi
  fi

  # set jdk path
  if [[ "$BUILD_JDK_VARIANT" = "$BISHENGJDK_8_BUILD_VARIANT" ]]; then
    BUILD_JDK_JDK_PATH=j2sdk-image
    BUILD_JDK_JRE_PATH=j2re-image
  else
    BUILD_JDK_JDK_PATH=jdk
    BUILD_JDK_JRE_PATH=jre
  fi
}

function GenerateBuildConfig () {
  PrintInfo "Get default configure args from ${ROOT_DIR}/sbin/common/constants_${BUILD_JDK_VARIANT}_${OS_ARCHITECTURE}.sh"
  source "${ROOT_DIR}/sbin/common/constants_${BUILD_JDK_VARIANT}_${OS_ARCHITECTURE}.sh"

  local build_configure_args=""

  # generate jdk configure args
  for key in ${!DEFAULT_CONFIGURE_ARGS[@]}
  do
    if [[ -n ${DEFAULT_CONFIGURE_ARGS[${key}]} ]]; then
        build_configure_args="$build_configure_args --${key}=\"${DEFAULT_CONFIGURE_ARGS[${key}]}\" "
    else
        build_configure_args="$build_configure_args --${key} "
    fi
  done

  build_configure_args=$(echo ${build_configure_args} | sed 's/[ ][ ]*/ /g')

  declare -A BUILD_CONFIG=(
    [BUILD_VARIANT]="$BUILD_JDK_VARIANT" \
    [MAJOR_NUMBER]="$BUILD_JDK_MAJOR" \
    [MINOR_NUMBER]="$BUILD_JDK_MINOR" \
    [BUILD_NUMBER]="$BUILD_JDK_BUILD_NUMBER" \
    [DEFAULT_CONFIGURE_ARGS]="${build_configure_args}" \
    [USER_SPECIFIED_CONFIGURE_ARGS]="${BUILD_JDK_USER_SPECIFIED_CONFIGURE_ARGS}" \
    [BOOT_JDK]="${BUILD_JDK_BOOT_JDK}" \
    [VENDOR_NAME]="${BISHENGJDK_VENDOR_NAME}" \
    [VENDOR_URL]="${BISHENGJDK_REPO_DEFAULT_URL[$BUILD_JDK_VARIANT]}" \
    [VENDOR_BUG_URL]="${BISHENGJDK_REPO_DEFAULT_URL[$BUILD_JDK_VARIANT]}issues/" \
    [VENDOR_VM_BUG_URL]="${BISHENGJDK_REPO_DEFAULT_URL[$BUILD_JDK_VARIANT]}issues/" \
    [JVM_VARIANT]="${BUILD_JDK_JVM_VARIANT}" \
    [DEFAULT_MAKE_ARGS]="${DEFAULT_MAKE_ARGS}" \
    [USER_SPECIFIED_MAKE_ARGS]="${BUILD_JDK_USER_SPECIFIED_MAKE_ARGS}" \
    [RELEASE_MAKE_TARGETS]="${RELEASE_MAKE_TARGETS}" \
    [WORKSPACE]="${BISHENGJDK_SOURCE_DIR}" \
    [OUTPUT_DIR]="${BISHENGJDK_OUTPUT_DIR}" \
    [CREATE_JRE_IMAGE]="${BUILD_JDK_CREATE_JRE_IMAGE}" \
    [OS]="${OS_NAME}" \
    [ARCH]="${OS_ARCHITECTURE}" \
    [BUILD_TYPE]="${BUILD_JDK_BUILD_TYPE}" \
    [JDK_PATH]="${BUILD_JDK_JDK_PATH}"
    [JRE_PATH]="${BUILD_JDK_JRE_PATH}"
    [TARGET_FILE_NAME]="${TARGET_FILE_TEMPLATE//REPLACE/$BUILD_JDK_MINOR}" \
  )

  if [[ "${BUILD_CONFIG[BUILD_TYPE]}" = "ci" ]]; then
    SetJtregTestCases
  fi

  ArchiveBuildConfig
}

function GetLastestTag () {
  local repo=$1
  local branch=master
  git clone "$repo" --branch "$branch" --depth 1 NOBODY_CARE > /dev/null 2>&1
  cd NOBODY_CARE
  git fetch --tags > /dev/null 2>&1
  local tag=$(git describe --tags --abbrev=0)
  cd - > /dev/null 2>&1
  rm -rf NOBODY_CARE || true
  echo "$tag"
}

function SetJtregTestCases () {
  # TO DO: make test cases can be choosen
  local testCases="test/hotspot/jtreg:tier1_runtime \
                   test/hotspot/jtreg:tier1_compiler_1 \
                   test/hotspot/jtreg:tier1_gc"
  if [[ "${BUILD_CONFIG[BUILD_VARIANT]}" = "${BISHENGJDK_8_BUILD_VARIANT}" ]]; then
    testCases="hotspot/test:hotspot_tier1 \
               jdk/test:jdk_tier1 \
               langtools/test:langtools_tier1"
  fi
  BUILD_CONFIG[JTREG_TEST_CASES]="$(echo ${testCases} | sed 's/[ ][ ]*/ /g')"

  BUILD_CONFIG[JTREG_TEST_EXCLUDE]="$(echo ${JTREG_TEST_EXCLUDE} | sed 's/[ ][ ]*/ /g')"

  BUILD_CONFIG[ABORT_RETEST_MAX_NUMBER]="$JREG_TEST_ABORT_RETEST_MAX_NUMBER"
}
