#!/bin/bash
# Copyright Huawei Technologies Co., Ltd. 2022. All rights reserved.

declare -A DEFAULT_CONFIGURE_ARGS=(
    [with-extra-cflags]="-fno-aggressive-loop-optimizations \
                        -fno-gnu-unique \
                        -Wno-unused-parameter \
                        " \
    [with-extra-ldflags]="-Wl,-z,now,--wrap=memcpy" \
    [enable-unlimited-crypto]=""
    [enable-jfr]="" \
)

export DEFAULT_MAKE_ARGS="LOG=debug"
export RELEASE_MAKE_TARGETS="images"
export TARGET_FILE_TEMPLATE="bisheng-jdk-8uREPLACE-linux-x64"
export JTREG_TEST_EXCLUDE="gc/g1/TestFromCardCacheIndex.java \
                           gc/g1/TestG1NUMATouchRegions.java \
                           com/sun/jdi/RedefineCrossEvent.java \
                           java/util/TimeZone/DefaultTimeZoneTest.java \
                           tools/javac/diags/CheckExamples.java \
                           testlibrary_tests/TestMutuallyExclusivePlatformPredicates.java \
                           compiler/rtm/locking/TestRTMAbortRatio.java \
                           compiler/rtm/locking/TestRTMAbortThreshold.java \
                           compiler/rtm/locking/TestRTMAfterNonRTMDeopt.java \
                           compiler/rtm/locking/TestRTMDeoptOnHighAbortRatio.java \
                           compiler/rtm/locking/TestRTMDeoptOnLowAbortRatio.java \
                           compiler/rtm/locking/TestRTMLockingCalculationDelay.java \
                           compiler/rtm/locking/TestRTMLockingThreshold.java \
                           compiler/rtm/locking/TestRTMRetryCount.java \
                           compiler/rtm/locking/TestRTMSpinLoopCount.java \
                           compiler/rtm/locking/TestRTMTotalCountIncrRate.java \
                           compiler/rtm/locking/TestUseRTMAfterLockInflation.java \
                           compiler/rtm/locking/TestUseRTMDeopt.java \
                           compiler/rtm/locking/TestUseRTMForInflatedLocks.java \
                           compiler/rtm/locking/TestUseRTMForStackLocks.java \
                           compiler/rtm/locking/TestUseRTMXendForLockBusy.java"
