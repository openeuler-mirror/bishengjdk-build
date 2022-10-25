#!/bin/bash
# Copyright Huawei Technologies Co., Ltd. 2022. All rights reserved.

declare -A DEFAULT_CONFIGURE_ARGS=(
    [with-extra-ldflags]="-Wl,-z,now,--wrap=memcpy" \
)

export DEFAULT_MAKE_ARGS="LOG=debug"
export RELEASE_MAKE_TARGETS="product-images legacy-jre-image"
export TARGET_FILE_TEMPLATE="bisheng-jdk-17.0.REPLACE-linux-x64"
export JTREG_TEST_EXCLUDE="runtime/cds/DeterministicDump.java \
                           gc/shenandoah/compiler/TestLinkToNativeRBP.java \
                           gc/stringdedup/TestStringDeduplicationAgeThreshold.java \
                           gc/stringdedup/TestStringDeduplicationFullGC.java \
                           gc/stringdedup/TestStringDeduplicationInterned.java \
                           gc/stringdedup/TestStringDeduplicationPrintOptions.java \
                           gc/stringdedup/TestStringDeduplicationTableResize.java \
                           gc/stringdedup/TestStringDeduplicationYoungGC.java \
                           gc/g1/humongousObjects/objectGraphTest/TestObjectGraphAfterGC.java \
                           runtime/exceptionMsgs/ArrayIndexOutOfBoundsException/ArrayIndexOutOfBoundsExceptionTest.java#id0 \
                           runtime/exceptionMsgs/ArrayIndexOutOfBoundsException/ArrayIndexOutOfBoundsExceptionTest.java#id1 \
                           runtime/exceptionMsgs/ArrayStoreException/ArrayStoreExceptionTest.java \
                           runtime/jsig/Testjsig.java \
                           runtime/logging/loadLibraryTest/LoadLibraryTest.java \
                           runtime/cds/serviceability/ReplaceCriticalClassesForSubgraphs.java \
                           gc/g1/TestPeriodicCollectionJNI.java \
                           runtime/Thread/SuspendAtExit.java \
                           gc/cslocker/TestCSLocker.java \
                           gc/TestJNIWeak/TestJNIWeak.java \
                           runtime/BoolReturn/JNIBooleanTest.java \
                           runtime/BoolReturn/NativeSmallIntCallsTest.java \
                           runtime/cds/serviceability/ReplaceCriticalClasses.java \
                           runtime/clinit/ClassInitBarrier.java \
                           runtime/DefineClass/NullClassBytesTest.java \
                           runtime/exceptionMsgs/NoClassDefFoundError/NoClassDefFoundErrorTest.java \
                           runtime/jni/8025979/UninitializedStrings.java \
                           runtime/jni/8033445/DefaultMethods.java \
                           runtime/jni/atExit/TestAtExit.java \
                           runtime/jni/CalleeSavedRegisters/FPRegs.java \
                           runtime/jni/CallWithJNIWeak/CallWithJNIWeak.java \
                           runtime/jni/checked/TestCheckedEnsureLocalCapacity.java \
                           runtime/jni/checked/TestCheckedJniExceptionCheck.java \
                           runtime/jni/checked/TestCheckedReleaseArrayElements.java \
                           runtime/jni/checked/TestCheckedReleaseCriticalArray.java \
                           runtime/jni/FastGetField/FastGetField.java \
                           runtime/jni/FindClass/FindClassFromBoot.java \
                           runtime/jni/FindClassUtf8/FindClassUtf8.java \
                           runtime/jni/PrivateInterfaceMethods/PrivateInterfaceMethods.java \
                           runtime/jni/registerNativesWarning/TestRegisterNativesWarning.java \
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
                           runtime/SameObject/SameObject.java \
                           runtime/StackGap/TestStackGap.java \
                           runtime/StackGuardPages/TestStackGuardPages.java \
                           runtime/TLS/TestTLS.java"
