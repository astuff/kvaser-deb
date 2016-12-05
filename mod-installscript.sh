#!/bin/bash

for d in */; do
    if [ -e "$d/mod-installscript.sh" ] ; then
        cd $d
        ./mod-installscript.sh
        cd ..
    fi
done

make -C canlib install
make -C linlib install
