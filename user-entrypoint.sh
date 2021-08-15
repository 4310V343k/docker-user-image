#!/usr/bin/env sh
set -euf

# Set the timezone if specified
if [ -n "${TZ:-}" ]; then
    if [ -f /etc/localtime ] && [ "$(stat -c "%d" "$(readlink -f /etc/localtime)")" -ne "$(stat -c "%d" /)" ]; then
        echo "/etc/localtime file mounted, ignoring environment variable TZ..."
    elif [ -f "/usr/share/zoneinfo/${TZ}" ]; then
        ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime
        if [ -f /etc/timezone ] && [ "$(stat -c "%d" "$(readlink -f /etc/timezone)")" -ne "$(stat -c "%d" /)" ]; then
            echo "Skipping /etc/timezone file update, as it is mounted from host"
        else
            echo "${TZ}" >/etc/timezone
        fi
        echo "Timezone set to ${TZ}"
    else
        echo "Environment variable TZ (${TZ}) is invalid, ignoring..."
    fi
fi

# Get the PUID and PGID, default to 1000 if not defined
PUID=${PUID:-1000}
PGID=${PGID:-${PUID}}

# Set permissions and custom exec commands, if applicable
if [ "${PUID}" -ne 0 ]; then
    # Non-root needs su-exec to run the command
    set "su-exec" "docker" "$@"

    usermod -o -u "${PUID}" docker >/dev/null 2>&1
    groupmod -o -g "${PGID}" docker >/dev/null 2>&1

    for folder in config data; do
        if [ ! -d "/${folder}" ]; then
            # Skip non-existant folders
            true
        elif [ ! -f "/${folder}/.permissions-set" ]; then
            # First run
            touch "/${folder}/.permissions-set"
            chown -R docker:docker "/${folder}"
        elif [ "$(stat -c "%u" "/${folder}/.permissions-set")" -ne "${PUID}" ] || [ "$(stat -c "%g" "/${folder}/.permissions-set")" -ne "${PGID}" ]; then
            # Subsequent run, PUID/PGID changed from previous run
            echo "Resetting all permissions in directory \"/${folder}\" to UID/GID: ${PUID}/${PGID}"
            chown -R docker:docker "/${folder}"
        else
            # Subsequent run, PUID/PGID have not changed. Still chown the directory in case this is volume mounted (folder would otherwise be owned by root)
            chown docker:docker "/${folder}"
        fi
    done
else
    for folder in config data; do
        if [ -f "/${folder}/.permissions-set" ]; then
            chown root:root "/${folder}/.permissions-set"
        fi
    done
fi

# Set niceness if defined
if [ -n "${NICENESS:-}" ]; then
    # NOTE: On debian systems, nice always has an exit code of `0`, even when
    # permission is denied. Look for the error message instead.
    if [ "$($(command -v nice) -n "${NICENESS}" true 2>&1)" != "" ]; then
        echo "ERROR: Permission denied to set application's niceness to" \
            "'${NICENESS}'. Make sure the container is started with the" \
            "'--cap-add=SYS_NICE' option. Exiting..."
        exit 1
    fi
    echo "Niceness set to ${NICENESS}"
    set "$(command -v nice)" "-n" "${NICENESS}" "$@"
fi

# Start the process!
if [ "${PUID}" -eq 0 ]; then
    echo "Starting as root user"
else
    echo "Starting with UID/GID: ${PUID}/${PGID}"
fi
exec "$@"
