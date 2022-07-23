#!/bin/bash -e
filename=${1%/*}
filename=${filename##*/}.git
repository_url=$(echo "$filename" | perl -pe 's/\%(\w\w)/chr hex $1/ge')
SUBJECT=$repository_url yq e -o=j '.subject=strenv(SUBJECT)' $1 | jq -f bin/json-post-processing-langcode.jq | jq -f bin/json-post-processing-subject.jq | jq -f bin/json-post-processing-date.jq
