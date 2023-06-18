#!/bin/bash
set -e

for ARG in "$@"
do
   KEY="$(echo $ARG | cut -f1 -d=)"
   VAL="$(echo $ARG | cut -f2 -d=)"
   export "$KEY"="$VAL"
done

ROOT_DIR=$(realpath $(dirname $0))
SGXSAN_DIR=$(realpath ${ROOT_DIR}/../../install)
WOLFSSL_MAKE_FLAGS="CC=clang-13 SGX_SDK=${SGXSAN_DIR} HAVE_WOLFSSL_TEST=1 HAVE_WOLFSSL_BENCHMARK=1 HAVE_WOLFSSL_SP=1 -j$(nproc)"
EXAMPLE_MAKE_FLAGS="CC=clang-13 CXX=clang++-13 LD=lld SGX_SDK=${SGXSAN_DIR} SGX_WOLFSSL_LIB=${ROOT_DIR}/wolfssl/IDE/LINUX-SGX/ WOLFSSL_ROOT=${ROOT_DIR}/wolfssl/ HAVE_WOLFSSL_TEST=1 HAVE_WOLFSSL_BENCHMARK=1 HAVE_WOLFSSL_SP=1 -j$(nproc)"
WOLFSSL_CFLAGS="-DGCM_TABLE_4BIT -fno-discard-value-names -flegacy-pass-manager -Xclang -load -Xclang ${SGXSAN_DIR}/lib64/libSGXSanPass.so"
MODE=${MODE:="RELEASE"}
FUZZER=${FUZZER:="LIBFUZZER"}
SIM=${SIM:="TRUE"}

echo "-- MODE: ${MODE}"
echo "-- FUZZER: ${FUZZER}"
echo "-- SIM: ${SIM}"

if [[ "${MODE}" = "DEBUG" ]]
then
    WOLFSSL_MAKE_FLAGS+=" SGX_DEBUG=1 SGX_PRERELEASE=0"
    EXAMPLE_MAKE_FLAGS+=" SGX_DEBUG=1 SGX_PRERELEASE=0"
else
    WOLFSSL_MAKE_FLAGS+=" SGX_DEBUG=0 SGX_PRERELEASE=1"
    EXAMPLE_MAKE_FLAGS+=" SGX_DEBUG=0 SGX_PRERELEASE=1"
fi

if [[ "${FUZZER}" = "KAFL" ]]
then
    EXAMPLE_MAKE_FLAGS+=" KAFL_FUZZER=1"
else
    EXAMPLE_MAKE_FLAGS+=" KAFL_FUZZER=0"
    WOLFSSL_CFLAGS+=" -flegacy-pass-manager -Xclang -load -Xclang ${SGXSAN_DIR}/lib64/libSGXFuzzerPass.so -mllvm --at-enclave=true -mllvm --instrument-json=${ROOT_DIR}/SGX_Linux/InstrumentStatistics.json"
fi

if [[ "${SIM}" = "TRUE" ]]
then
    EXAMPLE_MAKE_FLAGS+=" SGX_MODE=SIM"
else
    EXAMPLE_MAKE_FLAGS+=" SGX_MODE=HW"
fi

# same OPTION for non-SGX wolfssl
# ./configure --enable-rabbit --enable-des3 --disable-sha224 --disable-sha384 --disable-sha512 --disable-sha3 --disable-poly1305 --disable-chacha CC=clang CXX=clang++ CCAS=clang
touch ${ROOT_DIR}/wolfssl/wolfssl/options.h
CFLAGS=${WOLFSSL_CFLAGS} make -C ${ROOT_DIR}/wolfssl/IDE/LINUX-SGX -f sgx_t_static.mk ${WOLFSSL_MAKE_FLAGS}

make -C ${ROOT_DIR}/SGX_Linux ${EXAMPLE_MAKE_FLAGS}
