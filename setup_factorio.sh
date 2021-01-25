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
# - pv
# - tar (and either gzip or xz, depending on version)
readonly SCRIPT_DIR=$(cd $(dirname $0) && pwd)

readonly FACTORIO_LINK_TEMPLATE='https://factorio.com/get-download/{}/headless/linux64'
readonly FACTORIO_VERSION="${FACTORIO_VERSION:-latest}"
readonly FACTORIO_INSTALL_LOC="${FACTORIO_INSTALL_LOC:-/opt}"
readonly FACTORIO_USER="${FACTORIO_USER:-factorio}"


main () {
    local -r FACTORIO_LINK=$(echo "${FACTORIO_LINK_TEMPLATE}" | sed "s/{}/${FACTORIO_VERSION}/")
    local -r FACTORIO_PKG='/tmp/factorio.tar.cmp'

    local is_upgrade='false'
    # Download archive to /tmp
    echo "Downloading ${FACTORIO_VERSION} from ${FACTORIO_LINK}"
    curl -L# "${FACTORIO_LINK}" -o "${FACTORIO_PKG}"

    # Move existing factorio archive
    if [[ -d "${FACTORIO_INSTALL_LOC}/factorio" ]]; then
        # Only keep previous save - we don't need it if the past upgrade worked
        if [[ -d "${FACTORIO_INSTALL_LOC}/factorio.old" ]]; then
            echo "Existing backup. Delete? (y/n):"
            select "${to_delete}" in 'y' 'n'; do
                case "${to_delete}" in
                    'y' ) echo 'Deleting..'; rm -r "${FACTORIO_INSTALL_LOC}/factorio.old"
                    'n' ) echo 'Exiting..'; exit;;
                esac
            done
        fi
        echo "Moving existing install to ${FACTORIO_INSTALL_LOC}/factorio.old"
        mv "${FACTORIO_INSTALL_LOC}/factorio" "${FACTORIO_INSTALL_LOC}/factorio.old"
        is_upgrade='true'
    fi

    # Extract to final location
    if file -b "${FACTORIO_PKG}" | grep -q 'XZ'; then
        echo "Unzipping using xz"
        pv "${FACTORIO_PKG}" | tar -xJ -C "${FACTORIO_INSTALL_LOC}"
    elif file -b "${FACTORIO_PKG}" | grep -q 'gzip'; then
        echo "Unzipping using gzip"
        pv "${FACTORIO_PKG}" | tar -xz -C "${FACTORIO_INSTALL_LOC}"
    fi
    rm "${FACTORIO_PKG}"

    # If upgrade, carry continuity of installation
    if [[ "${is_upgrade}" = 'true' ]]; then
        echo 'Copying server metadata'
        local -r PERSISTENT_FILES=(\
            'mods' \
            'player-data.json' \
            'saves' \
            'server-adminlist.json' \
            'server-id.json' \
        )
        for "${file}" in "${PERSISTENT_FILES[@]}"; do
            mv "${FACTORIO_INSTALL_LOC}/factorio.old/${file}" "${FACTORIO_INSTALL_LOC}/factorio/${file}"
        done
    fi

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
