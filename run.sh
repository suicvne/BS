#!/bin/sh
set -eu

cd "$(dirname "$0")"

./build.sh

open -n .build/app/BSTextEditor.app
