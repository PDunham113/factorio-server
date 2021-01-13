#!/bin/bash
set -e
# This script will configure a server to host a headless Factorio game.
#
# By default, this will grab the latest experimental headless Factorio install
# for an x64 Linux system. This can be overridden by setting the
# `FACTORIO_VERSION` environment variable to either 'stable' (for the latest
# stable release) or a specific version number (e.g. '1.0.0'). Note that this
# number must match the version number _exactly_.
#
# Requires:
# - curl
# - tar (and either gzip or xz, depending on version)
readonly SCRIPT_DIR=$(cd $(dirname $0) && pwd)

readonly FACTORIO_LINK_TEMPLATE='https://factorio.com/get-download/{}/headless/linux64'
readonly FACTORIO_VERSION="${FACTORIO_VERSION:-latest}"
readonly FACTORIO_INSTALL_LOC="${FACTORIO_INSTALL_LOC:-/opt}"
readonly FACTORIO_USER="${FACTORIO_USER:-factorio}"


main () {
    local -r FACTORIO_LINK=$(echo "${FACTORIO_LINK_TEMPLATE}" | sed "s/{}/${FACTORIO_VERSION}/")
    local -r FACTORIO_PKG='factorio.tar.cmp'
    # Download archive to /tmp
    echo "Downloading ${FACTORIO_VERSION} from ${FACTORIO_LINK}"
    wget -q "${FACTORIO_LINK}" -O "${FACTORIO_PKG}"

    # Move existing factorio archive
    if [[ -d "${FACTORIO_INSTALL_LOC}/factorio" ]]; then
        echo "Moving existing install to ${FACTORIO_INSTALL_LOC}/factorio.old"
        mv "${FACTORIO_INSTALL_LOC}" "${FACTORIO_INSTALL_LOC}/factorio.old"
    fi

    # Extract to final location
    if file -b "${FACTORIO_PKG}" | grep -q 'XZ'; then
        echo "Unzipping using xz"
        tar -xJf "${FACTORIO_PKG}" -C "${FACTORIO_INSTALL_LOC}"
    elif file -b "${FACTORIO_PKG}" | grep -q 'gzip'; then
        echo "Unzipping using gzip"
        tar -xJf "${FACTORIO_PKG}" -C "${FACTORIO_INSTALL_LOC}"
    fi
    rm "/tmp/${FACTORIO_PKG}"

    # Create system user
    if id "${FACTORIO_USER}"; then
        echo 'Using existing user'
    else
        echo "Creating user ${FACTORIO_USER}"
        useradd -rU "${FACTORIO_USER}"
    fi
    chown -R "${FACTORIO_USER}:${FACTORIO_USER}" "${FACTORIO_INSTALL_LOC}/factorio"
}

main "$@"
