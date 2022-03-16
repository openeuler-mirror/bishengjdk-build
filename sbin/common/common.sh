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


function PrintError () {
  echo "[Error]: $1"
  exit 1
}

function PrintInfo () {
   echo "[Info]: $1" 
}

function PrintWarning () {
   echo "[Warning]: $1"
}

function CrossPlatformRealPath() {
  local target=$1

  local currentDir="$PWD"

  if [[ -d $target ]]; then
    cd "$target"
    local name=""
  elif [[ -f $target ]]; then
    cd "$(dirname "$target")"
    local name=$(basename "$target")
  fi

  local fullPath="$PWD/${name:+${name}}"
  cd "$currentDir"
  echo "$fullPath"
}

function CreateTarArchive() {
  local repoDir=$1
  local targetName=$2

  if [ -z "$repoDir" ]; then
    PrintError "Empty dir passed to be archived"
  fi

  if [[ "$repoDir" = "/"* ]]; then
     PrintError "Absolute directory passed to archive"
  fi

  COMPRESS=gzip
  if which pigz > /dev/null 2>&1; then
    COMPRESS=pigz
  fi
  PrintInfo "Archiving and compressing with $COMPRESS"

  # Create archive with UID/GID huawei/users if using GNU tar
  if tar --version 2>&1 | grep GNU > /dev/null; then
      time tar -cf - --owner=huawei --group=users "${repoDir}"/ | GZIP=-9 $COMPRESS -c > "$targetName.tar.gz"
  else
      time tar -cf - "${repoDir}"/ | GZIP=-9 $COMPRESS -c > "$targetName.tar.gz"
  fi

  archive="${PWD}/$targetName.tar.gz"

  PrintInfo "Your final archive was created at ${archive}"
}

function CreateCheckSum () {
  local targetName=$1

  PrintInfo "Creating sha256 for ${targetName} : ${targetName}.sha256"
  if which shasum256 > /dev/null 2>&1; then
    shasum256 "${targetName}" > "${targetName}.sha256"
  elif which shasum > /dev/null 2>&1; then
    shasum -a 256 "${targetName}" > "${targetName}.sha256"
  else
    PrintWarning "Shasum is not installed on the machine. Failed to generate ${targetName}.sha256"
  fi 
}

function ArchiveBuildConfig () {
  mkdir -p "$BISHENGJDK_DEFAULT_CONFIG_DIR"
  if [[ -f "$BISHENGJDK_DEFAULT_CONFIG_BUILD_CONFIG_FILE" ]]; then
    PrintInfo "Old BUILD_CONFIG is"
    cat "$BISHENGJDK_DEFAULT_CONFIG_BUILD_CONFIG_FILE"
  fi
  declare -p BUILD_CONFIG > "$BISHENGJDK_DEFAULT_CONFIG_BUILD_CONFIG_FILE"
}