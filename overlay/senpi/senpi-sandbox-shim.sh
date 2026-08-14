#!/usr/bin/env bash
set -u

cd "$1" || exit
export SENPI_BIN="$2"
shift 2
exec "@senpi-sandbox@" "$@"
