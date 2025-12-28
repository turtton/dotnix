#!/usr/bin/env sh

TARGET=$(efibootmgr -v | grep -P '(?<=^Boot)\d+(?=\* Windows Boot Manager)' -o)
pkexec efibootmgr --bootnext "${TARGET}"
systemctl reboot
