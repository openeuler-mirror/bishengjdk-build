#!/bin/bash
# Copyright Huawei Technologies Co., Ltd. 2022. All rights reserved.

declare -A DEFAULT_CONFIGURE_ARGS=(
    [with-extra-ldflags]="-Wl,-z,now" \
    [enable-kae]="yes" \

)

export DEFAULT_MAKE_ARGS="LOG=debug"
export RELEASE_MAKE_TARGETS="product-images legacy-jre-image"
export TARGET_FILE_TEMPLATE="bisheng-jdk-11.0.REPLACE-linux-aarch64"
export JTREG_TEST_EXCLUDE="runtime/exceptionMsgs/ArrayIndexOutOfBoundsException/ArrayIndexOutOfBoundsExceptionTest.java \
                           runtime/exceptionMsgs/ArrayStoreException/ArrayStoreExceptionTest.java \
                           runtime/StackGap/testme.sh \
                           runtime/StackGuardPages/testme.sh \
                           runtime/RedefineTests/RedefineDoubleDelete.java \
                           compiler/c2/aarch64/TestSVEWithJNI.java \
                           gc/cslocker/TestCSLocker.java \
                           gc/g1/TestJNIWeakG1/TestJNIWeakG1.java \
                           runtime/BoolReturn/JNIBooleanTest.java \
                           runtime/BoolReturn/NativeSmallIntCallsTest.java \
                           runtime/jni/8025979/UninitializedStrings.java \
                           runtime/jni/8033445/DefaultMethods.java \
                           runtime/jni/atExit/TestAtExit.java \
                           runtime/jni/CalleeSavedRegisters/FPRegs.java \
                           runtime/jni/CallWithJNIWeak/CallWithJNIWeak.java \
                           runtime/jni/checked/TestCheckedEnsureLocalCapacity.java \
                           runtime/jni/checked/TestCheckedJniExceptionCheck.java \
                           runtime/jni/checked/TestCheckedReleaseArrayElements.java \
                           runtime/jni/checked/TestCheckedReleaseCriticalArray.java \
                           runtime/jni/FindClass/FindClassFromBoot.java \
                           runtime/jni/PrivateInterfaceMethods/PrivateInterfaceMethods.java \
                           runtime/jni/ReturnJNIWeak/ReturnJNIWeak.java \
                           runtime/jni/terminatedThread/TestTerminatedThread.java \
                           runtime/jni/ToStringInInterfaceTest/ToStringTest.java \
                           runtime/modules/getModuleJNI/GetModule.java \
                           runtime/Nestmates/privateConstructors/TestJNI.java \
                           runtime/Nestmates/privateFields/TestJNI.java \
                           runtime/Nestmates/privateMethods/TestJNI.java \
                           runtime/Nestmates/privateMethods/TestJNIHierarchy.java \
                           runtime/Nestmates/privateStaticFields/TestJNI.java \
                           runtime/Nestmates/privateStaticMethods/TestJNI.java \
                           runtime/noClassDefFoundMsg/NoClassDefFoundMsg.java \
                           runtime/SameObject/SameObject.java \
                           runtime/SharedArchiveFile/serviceability/ReplaceCriticalClasses.java \
                           runtime/StackGuardPages/TestStackGuardPages.java \
                           runtime/StackGap/TestStackGap.java \
                           gc/survivorAlignment/TestPromotionToSurvivor.java"
