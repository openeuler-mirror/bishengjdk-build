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

source "${ROOT_DIR}/sbin/common/constants.sh"
source "${ROOT_DIR}/sbin/common/common.sh"

export CONFIGURE_ARGS=""

function AddConfigureArg () {
  # if the arg has been specified by the user, don't add it.
  if [[ ${BUILD_CONFIG[USER_SPECIFIED_CONFIGURE_ARGS]} != *"$1"* ]]; then
    if [[ $# -eq 1 ]]; then
      CONFIGURE_ARGS="$CONFIGURE_ARGS ${1}"
    else
      CONFIGURE_ARGS="$CONFIGURE_ARGS ${1}=${2}"
    fi
  fi
}

function ConfigureArgs () {
  local date=$(date -u +%Y-%m-%d-%H%M)
  CONFIGURE_ARGS="${BUILD_CONFIG[DEFAULT_CONFIGURE_ARGS]}"

  # jdk-version-string for different variant
  if [[ "${BUILD_CONFIG[BUILD_VARIANT]}" = "${BISHENGJDK_8_BUILD_VARIANT}" ]]; then
    AddConfigureArg "--with-update-version" "${BUILD_CONFIG[MINOR_NUMBER]}"
    local paddingNumber=$(printf "%02g" ${BUILD_CONFIG[BUILD_NUMBER]})
    AddConfigureArg "--with-build-number" "b${paddingNumber}"
  elif [[ "${BUILD_CONFIG[BUILD_VARIANT]}" = "${BISHENGJDK_11_BUILD_VARIANT}" || \
          "${BUILD_CONFIG[BUILD_VARIANT]}" = "${BISHENGJDK_17_BUILD_VARIANT}" ]]; then
    # update version comes with source code, so we don't set it here
    AddConfigureArg "--with-version-build" "${BUILD_CONFIG[BUILD_NUMBER]}"
  fi

  # set milestone or prefix for jdk
  if [[ "${BUILD_CONFIG[BUILD_TYPE]}" = "release" ]]; then
    if [[ "${BUILD_CONFIG[BUILD_VARIANT]}" = "${BISHENGJDK_8_BUILD_VARIANT}" ]]; then
      AddConfigureArg "--with-milestone" "fcs"
    else
      AddConfigureArg "--with-version-opt" ""
      AddConfigureArg "--with-version-pre" ""
    fi
  else
    if [[ "${BUILD_CONFIG[BUILD_VARIANT]}" = "${BISHENGJDK_8_BUILD_VARIANT}" ]]; then
      AddConfigureArg "--with-milestone" "beta"
    else
      AddConfigureArg "--with-version-opt" "${date}"
      AddConfigureArg "--with-version-pre" "beta"
    fi
  fi

  # set linking of C++ runtime on Linux
  if [[ "${BUILD_CONFIG[BUILD_VARIANT]}" = "${BISHENGJDK_8_BUILD_VARIANT}" ]]; then
    AddConfigureArg "--with-stdc++lib" "dynamic"
  fi

  # set debug symbols
  if [[ "${BUILD_CONFIG[BUILD_TYPE]}" = "ci" ]]; then
    AddConfigureArg "--with-debug-level" "release"
    AddConfigureArg "--with-native-debug-symbols" "external"
  fi
  if [[ "${BUILD_CONFIG[BUILD_TYPE]}" = "debug" ]]; then
    AddConfigureArg "--with-debug-level" "fastdebug"
    AddConfigureArg "--with-native-debug-symbols" "external"
  fi

  if [[ -n "${BUILD_CONFIG[BOOT_JDK]}" ]]; then
    AddConfigureArg "--with-boot-jdk" "${BUILD_CONFIG[BOOT_JDK]}"
  fi

  # add vendor related args
  AddConfigureArg "--with-vendor-name" "${BUILD_CONFIG[VENDOR_NAME]}"
  AddConfigureArg "--with-vendor-url" "${BUILD_CONFIG[VENDOR_URL]}"
  AddConfigureArg "--with-vendor-bug-url" "${BUILD_CONFIG[VENDOR_BUG_URL]}"
  AddConfigureArg "--with-vendor-vm-bug-url" "${BUILD_CONFIG[VENDOR_VM_BUG_URL]}"

  AddConfigureArg "--with-jvm-variants" "${BUILD_CONFIG[JVM_VARIANT]}"
  if [[ "${BUILD_CONFIG[MAJOR_NUMBER]}" -gt 8 ]]; then
    AddConfigureArg "--with-vendor-version-string" "${BUILD_CONFIG[VENDOR_NAME]}"
  fi

  # add bep configure option
  if [[ "${BUILD_CONFIG[BUILD_VARIANT]}" = "${BISHENGJDK_17_BUILD_VARIANT}" ]]; then
    AddConfigureArg "--with-source-date" "version"
  fi

  # put user specified args last position to make them the highest priority
  CONFIGURE_ARGS="${CONFIGURE_ARGS} ${BUILD_CONFIG[USER_SPECIFIED_CONFIGURE_ARGS]}"
}

function MakeTargets() {
  cd "${BUILD_CONFIG[WORKSPACE]}"
  rm -rf build || true
  mkdir -p "${BUILD_CONFIG[OUTPUT_DIR]}"
  echo "set +e"
  echo "bash configure $CONFIGURE_ARGS | tee ${BUILD_CONFIG[OUTPUT_DIR]}/configure.log" > config_make.sh
  echo "exitCode=\$?" >> config_make.sh
  echo "if [ \${exitCode} -ne 0 ]; then" >> config_make.sh
  echo "  exit 2;" >> config_make.sh
  echo "fi" >> config_make.sh
  echo "make ${BUILD_CONFIG[DEFAULT_MAKE_ARGS]} ${BUILD_CONFIG[USER_SPECIFIED_MAKE_ARGS]} ${BUILD_CONFIG[RELEASE_MAKE_TARGETS]}" >> config_make.sh
  echo "exitCode=\$?" >> config_make.sh
  echo "if [ \${exitCode} -ne 0 ]; then" >> config_make.sh
  echo "  exit 3;" >> config_make.sh
  echo "fi" >> config_make.sh
  bash ./config_make.sh
  if [[ $? -eq 2 ]]; then
    PrintError "JDK Configure Failed!"
  elif [[ $? -eq 3 ]]; then
    PrintError "Make JDK Failed!"
  fi
}

function GetJdkArchivePath () {
  if [[ "${BUILD_CONFIG[BUILD_VARIANT]}" = "${BISHENGJDK_8_BUILD_VARIANT}" ]]; then
    echo "bisheng-jdk1.8.0_${BUILD_CONFIG[MINOR_NUMBER]}"
  else
    echo "bisheng-jdk-${BUILD_CONFIG[MAJOR_NUMBER]}.0.${BUILD_CONFIG[MINOR_NUMBER]}"
  fi
}

function GetJreArchivePath () {
  echo $(GetJdkArchivePath) | sed 's/jdk/jre/'
}

function GetJdkDebugInfoArchivePath () {
  echo "$(GetJdkArchivePath)_debuginfo"
}

function GetJreDebugInfoArchivePath (){
  echo "$(GetJreArchivePath)_debuginfo"
}

# Clean up
function RemovingDebugFiles () {
  local jdkTargetPath=$(GetJdkArchivePath)
  local jreTargetPath=$(GetJreArchivePath)
  local jdkDebugInfoPath=$(GetJdkDebugInfoArchivePath)
  local jreDebugInfoPath=$(GetJreDebugInfoArchivePath)

  PrintInfo "Removing unnecessary files now..."

  cd "${BUILD_CONFIG[WORKSPACE]}"
  cd build/*/images || PrintError "JDK Build Image failed!"

  PrintInfo "Currently at '${PWD}'"

  local jdkPath=$(ls -d ${BUILD_CONFIG[JDK_PATH]})
  PrintInfo "Moving ${jdkPath} to ${jdkTargetPath}"
  rm -rf "${jdkTargetPath}" || true
  mv "${jdkPath}" "${jdkTargetPath}"

  if [[ "${BUILD_CONFIG[CREATE_JRE_IMAGE]}" = "true" ]]; then
    # Produce a JRE
    if [[ -d "$(ls -d ${BUILD_CONFIG[JRE_PATH]})" ]]; then
      PrintInfo "Moving $(ls -d ${BUILD_CONFIG[JRE_PATH]}) to ${jreTargetPath}"
      rm -rf "${jreTargetPath}" || true
      mv "$(ls -d ${BUILD_CONFIG[JRE_PATH]})" "${jreTargetPath}"
      rm -rf "${jreTargetPath}"/demo || true
    fi
  fi

  
  # Builds don't normally include debug symbols, but if they were explicitly 
  # requested via the configure option '--with-native-debug-symbols=(internal|external)' 
  # leave them alone.
  if [[ "${BUILD_CONFIG[BUILD_TYPE]}" = "release" ]]; then
    debugSymbols=$(find "${jdkTargetPath}" -type f -name "*.debuginfo")

   # if debug symbols were found, copy them to a different folder
    if [[ -n "${debugSymbols}" ]]; then
      CopyingAndRemovingDebuginfo ${jdkDebugInfoPath} ${jdkTargetPath}
      if [[ -d "${jreTargetPath}" ]]; then
        CopyingAndRemovingDebuginfo ${jreDebugInfoPath} ${jreTargetPath}
      fi
    fi
  fi

  PrintInfo "Finished removing debug symbols files from ${jdkTargetPath}"
}

function CopyingAndRemovingDebuginfo () {
  local debugInfoPath=$1
  local targetPath=$2

  PrintInfo "Copying found debug symbols to ${debugInfoPath}"
  mkdir -p "${debugInfoPath}"
  echo "$(find "${targetPath}" -type f -name "*.debuginfo")" | cpio -pdm "${debugInfoPath}"
  find "${targetPath}" -name "*.debuginfo" | xargs rm -f || true
}


function CreateArchive () {
  local jdkTargetPath=$(GetJdkArchivePath)
  local jreTargetPath=$(GetJreArchivePath)
  local jdkDebugInfoPath=$(GetJdkDebugInfoArchivePath)
  local jreDebugInfoPath=$(GetJreDebugInfoArchivePath)
  local jreName=$(echo "${BUILD_CONFIG[TARGET_FILE_NAME]}" | sed 's/jdk/jre/')

  cd "${BUILD_CONFIG[WORKSPACE]}"
  cd build/*/images || PrintError "JDK Build Image failed!"

  if [[ -d "${jreDebugInfoPath}" ]]; then
    PrintInfo "BiShengJDK debuginfo path := ${jreDebugInfoPath}"
    BuildJDKCreateTarArchive "${jreDebugInfoPath}" "$(echo "${jreName}_debuginfo")"
  fi

  if [[ -d "${jreTargetPath}" ]]; then
    PrintInfo "BiShengJDK JRE path := ${jreTargetPath}"
    BuildJDKCreateTarArchive "${jreTargetPath}" "${jreName}"
  fi
  if [[ -d "${jdkDebugInfoPath}" ]]; then
    PrintInfo "BiShengJDK debuginfo path := ${jdkDebugInfoPath}"
    BuildJDKCreateTarArchive "${jdkDebugInfoPath}" "$(echo "${BUILD_CONFIG[TARGET_FILE_NAME]}_debuginfo")"
  fi

  PrintInfo "BiShengJDK JDK path := ${jdkTargetPath}"
  BuildJDKCreateTarArchive "${jdkTargetPath}" "${BUILD_CONFIG[TARGET_FILE_NAME]}"
}

function BuildJDKCreateTarArchive () {
  local repoDir=$1
  local targetName=$2

  local fullPath=$(CrossPlatformRealPath "$repoDir")
  if [[ "$fullPath" != "${BUILD_CONFIG[WORKSPACE]}"* ]]; then
      PrintError "Requested to archive a dir outside of workspace"
  fi

  CreateTarArchive "$repoDir" "$targetName"

  PrintInfo "Moving the artifact to ${BUILD_CONFIG[OUTPUT_DIR]}"
  mkdir -p "${BUILD_CONFIG[OUTPUT_DIR]}"
  mv "${archive}" "${BUILD_CONFIG[OUTPUT_DIR]}/"
}

function AddCheckSumforArchiveBinaries () {
  local jdkName="${BUILD_CONFIG[TARGET_FILE_NAME]}.tar.gz"
  local jreName="$(echo ${BUILD_CONFIG[TARGET_FILE_NAME]} | sed 's/jdk/jre/').tar.gz"

  cd "${BUILD_CONFIG[OUTPUT_DIR]}"
  if [[ -f "${jreName}" ]]; then
    CreateCheckSum "${jreName}"
  fi
  CreateCheckSum "${jdkName}"
}

function BuildJDK () {
  source "$BISHENGJDK_DEFAULT_CONFIG_BUILD_CONFIG_FILE"

  ConfigureArgs
  MakeTargets
  RemovingDebugFiles
  CreateArchive
  if [[ "${BUILD_CONFIG[BUILD_TYPE]}" = "release" ]]; then
    AddCheckSumforArchiveBinaries
  fi
}
