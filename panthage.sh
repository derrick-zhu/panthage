#!/bin/sh
set -e
LANG="en_US.UTF-8"
LC_ALL=$LANG

export PATH="$(pwd)/tools":$PATH

params=''

for i in "$@"; do
    echo "$i"
    params="$params $i"
done

ruby tools/panthage_main.rb ${params}

