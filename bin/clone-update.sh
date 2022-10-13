#!/bin/bash -e
REPO=$(echo "$1" | perl -pe 's/\%(\w\w)/chr hex $1/ge')
if [ -d "workspace/cloned-repos/$1" ];
then
	echo "Updating $REPO"
	git -C workspace/cloned-repos/$1 fetch
else
	echo "Cloning into $REPO"
	git clone --filter=tree:0 --no-checkout $REPO workspace/cloned-repos/$1
fi
# Update the changed date on the directory, so we can use it to compare with tracked-repos.
touch workspace/cloned-repos/$1
