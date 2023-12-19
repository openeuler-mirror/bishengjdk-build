#!/bin/bash
# Copyright Huawei Technologies Co., Ltd. 2022. All rights reserved.

declare -A DEFAULT_CONFIGURE_ARGS=(
    [with-extra-cflags]="-fno-aggressive-loop-optimizations \
                        -fno-gnu-unique \
                        -fsigned-char \
                        -Wno-unused-parameter \
                        " \
    [with-extra-ldflags]="-Wl,-z,now" \
#    [enable-kae]="" \
    [enable-unlimited-crypto]="" \
)

export DEFAULT_MAKE_ARGS="LOG=debug"
export RELEASE_MAKE_TARGETS="images"
export TARGET_FILE_TEMPLATE="bisheng-jdk-21uREPLACE-linux-aarch64"

export JTREG_TEST_EXCLUDE=""
