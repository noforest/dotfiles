#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ristretto.sh <filename>"
    exit 1
fi

(nohup ristretto "$1" >/dev/null 2>&1 &) && dwmc viewex 2
