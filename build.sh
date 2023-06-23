#!/bin/bash
set -e

for ARG in "$@"
do
   KEY="$(echo $ARG | cut -f1 -d=)"
   VAL="$(echo $ARG | cut -f2 -d=)"
   export "$KEY"="$VAL"
done

ROOT_DIR=$(realpath $(dirname $0))
WOLFSSL_MAKE_FLAGS="HAVE_WOLFSSL_TEST=1 HAVE_WOLFSSL_BENCHMARK=1 HAVE_WOLFSSL_SP=1 -j$(nproc)"
EXAMPLE_MAKE_FLAGS="SGX_SDK=/opt/intel/sgxsdk SGX_WOLFSSL_LIB=${ROOT_DIR}/wolfssl/IDE/LINUX-SGX/ WOLFSSL_ROOT=${ROOT_DIR}/wolfssl/ HAVE_WOLFSSL_TEST=1 HAVE_WOLFSSL_BENCHMARK=1 HAVE_WOLFSSL_SP=1 -j1"
WOLFSSL_CFLAGS="-DGCM_TABLE_4BIT"
MODE=${MODE:="RELEASE"}
SIM=${SIM:="FALSE"}

echo "-- MODE: ${MODE}"
echo "-- SIM: ${SIM}"

if [[ "${MODE}" = "DEBUG" ]]
then
    WOLFSSL_MAKE_FLAGS+=" SGX_DEBUG=1 SGX_PRERELEASE=0"
    EXAMPLE_MAKE_FLAGS+=" SGX_DEBUG=1 SGX_PRERELEASE=0"
else
    WOLFSSL_MAKE_FLAGS+=" SGX_DEBUG=0 SGX_PRERELEASE=1"
    EXAMPLE_MAKE_FLAGS+=" SGX_DEBUG=0 SGX_PRERELEASE=1"
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
