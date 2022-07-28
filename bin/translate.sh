#!/bin/bash
# Usage: echo "Hallo" | translate.sh nl fr

# Input vars
SOURCE_LANG=$1
TARGET_LANG=$2
TEXT=$(cat -)

# Setup translation cache dir
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CACHE_DIR="$SCRIPT_DIR/../.translation_cache/"
mkdir -p $CACHE_DIR

REQUEST=$(jq --null-input \
  --arg source_lang "$SOURCE_LANG" \
  --arg target_lang "$TARGET_LANG" \
  --arg text "$TEXT" \
  '{"textToTranslate": $text, "sourceLanguage": $source_lang, "targetLanguage": $target_lang}')

CACHE_ID=$(echo $REQUEST | sha1sum | cut -f1 -d' ') 
if [ ! -f "$CACHE_DIR$CACHE_ID" ];
then
	curl -s -H 'Content-Type: application/json' --data-binary "$REQUEST" https://europa.eu/webtools/rest/etrans/translate | jq -r .translation | base64 -d > $CACHE_DIR$CACHE_ID
fi
cat $CACHE_DIR$CACHE_ID
