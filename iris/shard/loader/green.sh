#!/bin/bash
source ./envs.sh
java -Dfile.encoding=UTF-8 -cp $ISCCLASSLIBS com.intersystems.datatransfer.SimpleMover p=green.conf