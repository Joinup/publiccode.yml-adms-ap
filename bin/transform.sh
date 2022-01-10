#!/bin/bash -e
directory=${1%/*}
cd $directory
java -jar ../../../tools/rmlmapper.jar -m ../../../publiccode-to-adms.ttl
