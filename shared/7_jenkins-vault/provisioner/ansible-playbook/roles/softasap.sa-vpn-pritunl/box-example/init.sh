#!/bin/bash

git config -f .projmodules --get-regexp '^submodule\..*\.path$' > tempfile

while read -u 3 path_key path
do
    url_key=$(echo $path_key | sed 's/\.path/.url/')
    url=$(git config -f .projmodules --get "$url_key")

    read -p "Are you sure you want to delete $path and re-initialize as a separate repository? " yn
    case $yn in
        [Yy]* ) rm -rf $path; git clone $url $path; echo "$path has been initialized";;
        [Nn]* ) continue;;
        * ) echo "Please answer yes or no.";;
    esac

done 3<tempfile

rm tempfile

echo Project was checked out