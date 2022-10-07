#!/bin/bash -e
directory=${1%/*}
cd $directory
java -jar ../../../tools/rmlmapper.jar -v --strict -m ../../../publiccode-to-adms.ttl -b http://example.com/
