#!/usr/bin/env sh

CURRENT_DIR=$(readlink -m $(dirname $0))

# default packages file if not given via ENVIRONMENT
if [ -z "$WGET_PACKAGES_FILE" ] ; then
    WGET_PACKAGES_FILE=$(readlink -m "${CURRENT_DIR}/package.txt")
fi

echo "[INFO] Downloading packages listed in:" $WGET_PACKAGES_FILE

# remove lines with comments from the packages file
TEMPFILE=$(mktemp)
grep -v -e"^$" -e"^\s*#" $WGET_PACKAGES_FILE > $TEMPFILE

# per line: download file to target path and check sha1 checksum
while read LINE
do
    URL=$(echo "$LINE" | cut -d' ' -f1)
    FILE=$(echo "$LINE" | cut -d' ' -f2)
    SHA1=$(echo "$LINE" | cut -d' ' -f3)

    # validation (haha)
    if [ $URL = $FILE ] ; then
        echo "[ERROR] Invalid wget download instruction. URL and filename are the same:" $LINE
        continue
    fi
    if [ $FILE = $SHA1 ] ; then
        echo "[ERROR] Invalid wget download instruction. Filename and checksum are the same:" $LINE
        continue
    fi
    if [ $URL = $SHA1 ] ; then
        echo "[ERROR] Invalid wget download instruction. Sha1 value the same as the URL:" $LINE
        continue
    fi

    # check if local file already exists and has the correct checksum
    if [ -f $FILE ] ; then
        CHECKSUM=$(sha1sum $FILE)
        CHECKSUM=$(echo "$CHECKSUM" | cut -d' ' -f1)
        if [ "$CHECKSUM" = "$SHA1" ] ; then
            echo "[SUCCESS] File already downloaded correctly:" $FILE
            continue
        else
            echo "[INFO] File checksum mismatch. Fetching file:" $FILE
        fi
    fi

    # download file
    wget --continue -O $FILE -- $URL
    if [ $? -ne 0 ]; then
        echo "[ERROR] Download failed from:" $URL
    fi

    # verify downloaded file
    echo "[INFO] Calculating checksum for file:" $FILE
    CHECKSUM=$(sha1sum $FILE)
    CHECKSUM=$(echo "$CHECKSUM" | cut -d' ' -f1)
    if [ "$CHECKSUM" = "$SHA1" ] ; then
        echo "[SUCCESS] Download succesful:" $FILE
    else
        echo "[ERROR] Checksum error for downloaded file:" $FILE
        echo "[ERROR] Expected   =>" $SHA1
        echo "[ERROR] Calculated =>" $CHECKSUM
    fi
done < $TEMPFILE

rm $TEMPFILE

