#!/bin/bash
self=$(readlink -f "${BASH_SOURCE[0]}")
cp $self /usr/lib/virt-sysprep/scripts/$(basename $self)-retry.sh

#do stuff that may fail (eg: missing network). if it fails exit before the rm line below so the script will be retried at next boot

rm /usr/lib/virt-sysprep/scripts/$(basename $self)-retry.sh