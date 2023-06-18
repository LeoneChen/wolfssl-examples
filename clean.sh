#!/bin/bash
set -e

make -C wolfssl/IDE/LINUX-SGX -f sgx_t_static.mk clean -s
make -C SGX_Linux clean -s WOLFSSL_ROOT=none
