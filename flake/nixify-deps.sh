#!/usr/bin/env bash

set -e

DEPSFILE=$1
OUTFILE=$2

touch $OUTFILE
truncate -s 0 $OUTFILE

if [ ! -f "$DEPSFILE" ]; then
    echo "Depsfile \"${DEPSFILE}\" does not exist"
    exit 1
fi

TMPFILE=$(mktemp -t nixify-deps.XXX)

echo "[" >> $OUTFILE

while IFS=";" read -r name url sha1
do
    echo ""
    echo "Processing Dependency: '$name'"
    echo "Downloading from '$url'"
    wget "$url" -O $TMPFILE 2> /dev/null
    echo -n "Checking SHA hash... "
    FILEHASH=($(shasum $TMPFILE))
    if [ "$sha1" = "$FILEHASH" ]; then
        echo "SUCCESS"
    else
        echo "FAILED, '$sha1' != '$FILEHASH'"
        exit 2
    fi
    NIXHASH=$(nix hash file $TMPFILE)
    echo "Nix SHA256 hash: $NIXHASH"
    echo "{" >> $OUTFILE
    echo "name = \"$name\";" >> $OUTFILE
    echo "sha1 = \"$sha1\";" >> $OUTFILE
    echo "file = fetchurl {" >> $OUTFILE
    echo "url = \"$url\";" >> $OUTFILE
    echo "sha256 = \"$NIXHASH\";" >> $OUTFILE
    echo "};" >> $OUTFILE
    echo "}" >> $OUTFILE
done < <(cat ../onnxruntime/cmake/deps.txt | grep -v "#")

echo "]" >> $OUTFILE
echo "Formatting output file"
nixfmt $OUTFILE