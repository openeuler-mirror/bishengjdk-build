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
                           gc/g1/TestG1NUMATouchRegions.java"