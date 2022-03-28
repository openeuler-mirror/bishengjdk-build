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

JTREG_REPORT_RESULT_FILES_DIR="${ROOT_DIR}/test/jtreg"
JTREG_CMD=

function TestJDK () {
  source "$BISHENGJDK_DEFAULT_CONFIG_BUILD_CONFIG_FILE"

  if [[ "${BUILD_CONFIG[BUILD_TYPE]}" != "ci" ]]; then
    return 0
  fi

  InitJtregCommand
  AddVerbose summary

  rm -rf "${JTREG_REPORT_RESULT_FILES_DIR}" || true
  AddTestWorkDir work
  AddTestReportDir report

  # Add exclude file for jtreg tests
  cd "${JTREG_REPORT_RESULT_FILES_DIR}"
  touch exclude.txt
  echo "${BUILD_CONFIG[JTREG_TEST_EXCLUDE]}" | tr ' ' '\n' > exclude.txt
  AddExcludeFile "${JTREG_REPORT_RESULT_FILES_DIR}/exclude.txt"

  PrintInfo "Jtreg tests begin"
  local jtregTestLog="${JTREG_REPORT_RESULT_FILES_DIR}/jtreg_test.log"
  echo "${BUILD_CONFIG[JTREG_TEST_CASES]}" > "${JTREG_REPORT_RESULT_FILES_DIR}/testcases.txt"
  RunTestCases "${JTREG_REPORT_RESULT_FILES_DIR}/testcases.txt" "$jtregTestLog"

  local failLog="${JTREG_REPORT_RESULT_FILES_DIR}/fail.log"
  local errorLog="${JTREG_REPORT_RESULT_FILES_DIR}/error.log"
  GenerateFailedandErrorLogFromSummaryLog "$jtregTestLog" "$failLog" "$errorLog"

  cat "$errorLog" >> "$failLog"
  if [[ "$(cat $failLog | wc -l)" -ne 0 ]]; then
    PrintInfo "Retest failed and error testcases"
    InitJtregCommand
    AddVerbose all
    AddTestWorkDir work_final
    AddTestReportDir report_final
    local finalFailLog="${JTREG_REPORT_RESULT_FILES_DIR}/fail_final.log"
    local finalErrorLog="${JTREG_REPORT_RESULT_FILES_DIR}/error_final.log"
    local finalJtregTestLog="${JTREG_REPORT_RESULT_FILES_DIR}/jtreg_test_final.log"
    RunTestCases "$failLog" "$finalJtregTestLog"

    if cat "$finalJtregTestLog" | grep "^Test results:" | grep -E "(fail|error)"; then
      PrintError "Tests failed. Please Check report in ${JTREG_REPORT_RESULT_FILES_DIR}"
    fi
  fi

  PrintInfo "Jtreg test finished. All tests passed."
}

function InitJtregCommand () {
  JTREG_CMD="${BUILD_CONFIG[JTREG_HOME]}/bin/jtreg"
  AddTestJDKDir
  AddIgnoreQuiet
}

function AddVerbose () {
  JTREG_CMD="$JTREG_CMD -v:$(echo $* | tr ' ' ',')"
}

function AddTestWorkDir () {
  mkdir -p "${JTREG_REPORT_RESULT_FILES_DIR}"
  local dir="${JTREG_REPORT_RESULT_FILES_DIR}/$1"
  rm -rf "$dir" || true
  JTREG_CMD="$JTREG_CMD -w $dir"
}

function AddTestReportDir () {
  mkdir -p "${JTREG_REPORT_RESULT_FILES_DIR}"
  local dir="${JTREG_REPORT_RESULT_FILES_DIR}/$1"
  rm -rf "$dir" || true
  JTREG_CMD="$JTREG_CMD -r $dir"
}

function AddTestJDKDir () {
  local jdkPath="${BISHENGJDK_DEFAULT_TEMP_DIR}/$(GetJdkArchivePath)"
  if [[ ! -d "$jdkPath" ]]; then
    PrintInfo "Moving and uncompressing ${BUILD_CONFIG[TARGET_FILE_NAME]}.tar.gz to ${BISHENGJDK_DEFAULT_TEMP_DIR}"
    cp "${BUILD_CONFIG[OUTPUT_DIR]}"/"${BUILD_CONFIG[TARGET_FILE_NAME]}.tar.gz" "${BISHENGJDK_DEFAULT_TEMP_DIR}"
    cd "${BISHENGJDK_DEFAULT_TEMP_DIR}"
    tar -xf "${BUILD_CONFIG[TARGET_FILE_NAME]}.tar.gz"
    if [[ -d "$jdkPath" ]]; then
      PrintInfo "Uncompress ${BUILD_CONFIG[TARGET_FILE_NAME]}.tar.gz successfully"
    else
      ls
      PrintError "JDK not exists after Uncompressing"
    fi
    rm -f *.tar.gz || true
  fi

  JTREG_CMD="$JTREG_CMD -jdk:$jdkPath"
}

function AddExcludeFile () {
  PrintInfo "Exclude tests:"
  cat "$1"
  JTREG_CMD="$JTREG_CMD -exclude:$1"
}

function AddIgnoreQuiet () {
  PrintInfo "Jtreg tests quient ignore tests"
  JTREG_CMD="$JTREG_CMD -ignore:quiet"
}

function RunTestCases () {
  local testcasesFile=$1
  local logName=$2

  PrintInfo "TestcaseFile: $testcasesFile"
  cat "$testcasesFile" | tr ' ' '\n' > "${testcasesFile}.tmp"
  cat "${testcasesFile}.tmp"
  PrintInfo "JtregLogFile: $logName"

  local realTestcases=""
  cd "${BUILD_CONFIG[WORKSPACE]}"
  while read line; do
    if [[ -z "$line" ]]; then
      continue
    elif [[ "$line" = *.sh || "$line" = *.java ]]; then
      local testPath="$(find . -name $(basename $line) | grep $line)"
      realTestcases="${realTestcases} ${testPath}"
    else
      realTestcases="${realTestcases} ${line}"
    fi
  done < "${testcasesFile}.tmp"

  PrintInfo "jtregCmd: $JTREG_CMD $realTestcases"
  JTREG_CMD="$JTREG_CMD $realTestcases"
  eval $JTREG_CMD | tee "$logName"
}

function GenerateFailedandErrorLogFromSummaryLog () {
  local jtregTestLog=$1
  local failLog=$2
  local errorLog=$3

  rm -f "$failLog" "$errorLog" || true
  touch "$failLog" "$errorLog"
  while read line; do
    if [[ "$line" = "FAILED:"* ]]; then
      echo $line | sed "s/^FAILED: //" >> "$failLog"
    fi
    if [[ "$line" = "Error:"* ]]; then
      echo $line | sed "s/^Error: //" >> "$errorLog"
    fi
  done < "$jtregTestLog"
  PrintInfo "Failed Tests: "
  cat "$failLog"
  PrintInfo "Error Tests: "
  cat "$errorLog"
}