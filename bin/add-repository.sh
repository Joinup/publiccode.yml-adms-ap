#!/bin/bash -e
encoded=$(echo "$1" | perl -MURI::Escape -wlne 'print uri_escape $_')
touch "tracked-repos/$encoded"
