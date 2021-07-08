#!/bin/bash
build_dir="ErrorLogs"
if [ ! -d "$build_dir" ]; then
        mkdir $build_dir
fi
cd "ErrorLogs"
rm -rf *
/etc/daocloud/dce/sbin/dce-sos getlocallogs
tar xzf dce-sos-logs.tar.gz
grep -r error  /root/ErrorLogs/*parcel*>ParcelError.log
grep -r error  /root/ErrorLogs>Error.log
pwd
