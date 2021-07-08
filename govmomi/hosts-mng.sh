#!/bin/bash

# simple scripts mng machine

# link hosts

export GOVC_INSECURE=1
export GOVC_USERNAME="bingzhe.sun@vsphere.local"
export GOVC_PASSWORD="Bingzhe@2021"
export GOVC_URL="https://192.168.1.136:443"
export GOVC_DATACENTER="NDC"
export GOVC_RESOURCE_POOL="60-DCE-405-rhel8.1"
export hosts="M-60-11 M-60-12 M-60-13 N-60-14 N-60-15"
export snapshot="begin"
# for h in hosts; do govc vm.power -off -force $h; done
# for h in hosts; do govc snapshot.revert -vm $h "机器配置2"; done
# for h in hosts; do govc vm.power -on -force $h; done

# govc vm.info $hosts[0].Power state
# govc find . -type m -runtime.powerState poweredOn
# govc find . -type m -runtime.powerState poweredOn | xargs govc vm.info
# govc vm.info $hosts


for h in $hosts; do
  if [[ `govc vm.info $h | grep poweredOn | wc -l` -eq 1 ]]; then
    govc vm.power -off -force $h
    echo -e "\033[35m === $h has been down === \033[0m"
  fi

  govc snapshot.revert -vm $h $snapshot
  echo -e "\033[35m === $h reverted to snapshot: `govc snapshot.tree -vm $h -C -D -i -d` === \033[0m"

  govc vm.power -on $h
  echo -e "\033[35m === $h: power turned on === \033[0m"
done

echo -e "\033[35m === task will end in 1m 30s === \033[0m"
for i in `seq 1 15`; do
  echo -e "\033[35m === `date  '+%Y-%m-%d %H:%M:%S'` === \033[0m"
  sleep 6s
done
