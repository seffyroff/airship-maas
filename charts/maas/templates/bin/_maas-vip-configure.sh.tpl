#!/bin/bash

{{/*
Copyright 2018 The Openstack-Helm Authors.
Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.*/}}

set -ex

COMMAND="${@:-start}"

function kernel_modules () {
  chroot /mnt/host-rootfs modprobe dummy
}

function test_vip () {
  ip addr show ${interface} | \
    awk "/inet / && /${interface}/{print \$2 }" | \
    awk -F '/' '{ print $1 }' | \
    grep -q "${addr%/*}"
}

function start () {
  kernel_modules
  ip link show ${interface} > /dev/null || ip link add ${interface} type dummy
  if ! test_vip; then
   ip addr add ${addr} dev ${interface}
  fi
  ip link set ${interface} up
}

function sleep () {
  exec /usr/bin/dumb-init bash -c "while :; do sleep 2073600; done"
}

function stop () {
  ip link show ${interface} > /dev/null || exit 0
  if test_vip; then
   ip addr del ${addr} dev ${interface}
  fi
  if [ "$(ip address show ${interface} | \
          awk "/inet / && /${interface}/{print \$2 }" | \
          wc -l)" -le "0" ]; then
    ip link set ${interface} down
    ip link del ${interface}
  fi
}

$COMMAND
