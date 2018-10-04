#!/bin/bash
#
# Example of an entrypoint for Python/Django apps
#

# Exit immediately if a command exits with a non-zero status.
# http://stackoverflow.com/questions/19622198/what-does-set-e-mean-in-a-bash-script
set -e

# Define help message
show_help() {
    echo """
Usage: docker run <imagename> COMMAND

Commands

bash    : Start a bash shell
manage  : Start manage.py
python  : Run a python command
db      : Start a Django DB shell.
shell   : Start a Django Python shell.
help    : Show this message
"""
}

wait_for() {
    # Wait for hosts specified in WAIT_FOR
    echo "Waiting for neighbors..." >&2
    TIMEOUT=${TIMEOUT:-45}
    result=0    # exit right away if list is empty
    for i in $(seq "$TIMEOUT"); do
        for TARGET in $WAIT_FOR; do
            HOST=$(printf "%s\n" "$TARGET"| cut -d : -f 1)
            PORT=$(printf "%s\n" "$TARGET"| cut -d : -f 2)
            set +e
            timeout 1 bash -c "cat < /dev/null > /dev/tcp/$HOST/$PORT"
            result=$?
            set -e
            if [ "$result" -ne 0 ] ; then
                sleep 1
                break
            fi
        done
        if [ $result -eq 0 ]; then
            break
        fi
    done
    if [ $result -ne 0 ]; then
        echo "Operation timed out" >&2
        exit 1
    fi
    echo "Done waiting" >&2
}

initdb() {
    if [ ${INITDB:-0} -eq 1 ]; then
        echo "Initializing database..." >&2
        python ./src/manage.py migrate --run-syncdb
        echo "Initializing database complete" >&2
    fi
}

setup_commands() {
    if [ ! -z "$SETUP_CMD" ]; then
      echo "Running setup commands..."
      bash -c "$SETUP_CMD"
      echo "Done setting up"
    fi
}

wait_for
initdb
setup_commands

# Run
case "$1" in
    bash)
        exec /bin/bash "${@:2}"
    ;;
    manage)
        exec python ./src/manage.py "${@:2}"
    ;;
    runserver)
        exec python ./src/manage.py runserver "${@:2}"
    ;;
    python)
        exec python "${@:2}"
    ;;
    db)
        exec python ./src/manage.py dbshell "${@:2}"
    ;;
    shell)
        exec python ./src/manage.py shell_plus "${@:2}"
    ;;
    worker)
        # A bit too much hardcoded stuff, might require some review
        exec celery --app="$APP" worker -c 1 --maxtasksperchild=512 -l info --workdir="$BASE_DIR" "${@:2}"
    ;;
    cron)
        exec celery --app="$APP" beat -s var/celerybeat-schedule -l info --workdir="$BASE_DIR" "${@:2}"
    ;;
    help)
        show_help
    ;;
    *)
        exec "${@}"  # running default CMD
    ;;
esac
