#!/bin/sh

# The URL of the script project is:
# https://github.com/XTLS/xxxx-install

FILES_PATH=${FILES_PATH:-./}

# Gobal verbals

# xxxx current version
CURRENT_VERSION=''

# xxxx latest release version
RELEASE_LATEST=''

get_current_version() {
    # Get the CURRENT_VERSION
    if [[ -f "${FILES_PATH}/web" ]]; then
        CURRENT_VERSION="$(${FILES_PATH}/web -version | awk 'NR==1 {print $2}')"
        CURRENT_VERSION="v${CURRENT_VERSION#v}"
    else
        CURRENT_VERSION=""
    fi
}
# HRS修改 fix 直接给它修改成github最新版本号，给下面赋值 RELEASE_LATEST="v1.7.5"
get_latest_version() {
    # Get Xray latest release version number
    local tmp_file
    tmp_file="$(mktemp)"
    if ! curl -sS -H "Accept: application/vnd.github.v3+json" -o "$tmp_file" 'https://github.com/hrshappy/xxx/blob/main/happy'; then
        "rm" "$tmp_file"
        echo 'error: Failed to get release list, please check your network.'
        exit 1
    fi
    RELEASE_LATEST="v1.7.5"
    if [[ -z "$RELEASE_LATEST" ]]; then
        if grep -q "API rate limit exceeded" "$tmp_file"; then
            echo "error: github API rate limit exceeded"
        else
            echo "error: Failed to get the latest release version."
        fi
        "rm" "$tmp_file"
        exit 1
    fi
    "rm" "$tmp_file"
}
# HRS修改 fix 直接换链接DOWNLOAD_LINK="https://raw.githubusercontent.com/hrshappy/xxx/main/xxxx-linux-64.zip"
download_xxxx() {
    DOWNLOAD_LINK="https://raw.githubusercontent.com/hrshappy/xxx/main/xxxx-linux-64.zip"
    if ! wget -qO "$ZIP_FILE" "$DOWNLOAD_LINK"; then
        echo 'error: Download failed! Please check your network or try again.'
        return 1
    fi
    return 0
    if ! wget -qO "$ZIP_FILE.dgst" "$DOWNLOAD_LINK.dgst"; then
        echo 'error: Download failed! Please check your network or try again.'
        return 1
    fi
    if [[ "$(cat "$ZIP_FILE".dgst)" == 'Not Found' ]]; then
        echo 'error: This version does not support verification. Please replace with another version.'
        return 1
    fi

    # Verification of xxxx archive
    for LISTSUM in 'md5' 'sha1' 'sha256' 'sha512'; do
        SUM="$(${LISTSUM}sum "$ZIP_FILE" | sed 's/ .*//')"
        CHECKSUM="$(grep ${LISTSUM^^} "$ZIP_FILE".dgst | grep "$SUM" -o -a | uniq)"
        if [[ "$SUM" != "$CHECKSUM" ]]; then
            echo 'error: Check failed! Please check your network or try again.'
            return 1
        fi
    done
}

decompression() {
    busybox unzip -q "$1" -d "$TMP_DIRECTORY"
    EXIT_CODE=$?
    if [ ${EXIT_CODE} -ne 0 ]; then
        "rm" -r "$TMP_DIRECTORY"
        echo "removed: $TMP_DIRECTORY"
        exit 1
    fi
}

install_xxxx() {
    install -m 755 ${TMP_DIRECTORY}/${FILES_PATH}/web
}

run_xxxx() {
    re_uuid=$(curl -s $REPLIT_DB_URL/re_uuid)   
    if [ "${re_uuid}" = "" ]; then
        new_uuid="$(cat /proc/sys/kernel/random/uuid)"
        curl -sXPOST $REPLIT_DB_URL/re_uuid="${new_uuid}" 
    fi

    if [ "${uuid}" = "" ]; then
        user_uuid=$(curl -s $REPLIT_DB_URL/re_uuid)
    else
        user_uuid=${uuid}
    fi

    cp -f ./config.yaml /tmp/config.yaml
    sed -i "s|uuid|${user_uuid}|g" /tmp/config.yaml
    ./web -c /tmp/config.yaml 2>&1 >/dev/null &
    replit_xxxx_vmess="vmess://$(echo -n "\
{\
\"v\": \"2\",\
\"ps\": \"replit_xxxx_vmess\",\
\"add\": \"${REPL_SLUG}.${REPL_OWNER}.repl.co\",\
\"port\": \"443\",\
\"id\": \"$user_uuid\",\
\"aid\": \"0\",\
\"net\": \"ws\",\
\"type\": \"none\",\
\"host\": \"${REPL_SLUG}.${REPL_OWNER}.repl.co\",\
\"path\": \"/$user_uuid\",\
\"tls\": \"tls\"\
}"\
    | base64 -w 0)"   
    echo ""
    echo "Share Link:"
    echo ${replit_xxxx_vmess}
    echo ""
    qrencode -t ansiutf8 ${replit_xxxx_vmess}
    echo ""
    while true; do
      curl "https://${REPL_SLUG}.${REPL_OWNER}.repl.co"
      sleep 60
    done
}

# Two very important variables
TMP_DIRECTORY="$(mktemp -d)"
ZIP_FILE="${TMP_DIRECTORY}/web.zip"

get_current_version
get_latest_version
if [ "${RELEASE_LATEST}" = "${CURRENT_VERSION}" ]; then
    "rm" -rf "$TMP_DIRECTORY"
    run_xxxx
fi
download_xxxx
EXIT_CODE=$?
if [ ${EXIT_CODE} -eq 0 ]; then
    :
else
    "rm" -r "$TMP_DIRECTORY"
    echo "removed: $TMP_DIRECTORY"
    run_xxxx
fi
decompression "$ZIP_FILE"
install_xxxx
"rm" -rf "$TMP_DIRECTORY"

run_xxxx
