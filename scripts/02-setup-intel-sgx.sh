#!/bin/bash

branch_name=sgx_driver_2.5

# Dependencies
yes | apt-get update
yes | apt-get install git python make linux-headers-$(uname -r) gcc

# SGX driver
git clone -b ${branch_name} https://github.com/01org/linux-sgx-driver.git
cd linux-sgx-driver

make
mkdir -p "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"
cp isgx.ko "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"
sh -c "cat /etc/modules | grep -Fxq isgx || echo isgx >> /etc/modules"
/sbin/depmod
/sbin/modprobe isgx
cd ..
rm -rf linux-sgx-driver

