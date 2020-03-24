#!/usr/bin/env bash

# creates links from files in one dir to another dir

if [ -z $1 ]; then echo "Usage: linkloop.sh pathToServer/SequencingRun/ pathToCreateLinks/"; exit 1 ; fi

if [ $1 == "-h" ] || [ $1 == "-help" ]; then 
    echo "Usage: linkloop.sh pathToServer/SequencingRun/ pathToCreateLinks/"
    echo "  First parameter is a dir which contains fast5 files somewhere"
    echo "  This script looks recursively for fast5 files!"
    echo "  And creates softlinks for Nextflows watchPath"
    exit 0
fi

if [ -z $2 ]; then echo "Usage: linkloop.sh pathToServer/SequencingRun/ pathToCreateLinks/"; exit 1; fi

mkdir -p $2

while true; do
        for fast5_file in $(find $1 -name '*.fast5') ; do
                filename=$(basename ${fast5_file})
                ln -s ${fast5_file} $2/${filename} 2>/dev/null
        done
    sleep 10m
done