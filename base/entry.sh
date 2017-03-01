#!/bin/bash
log() {
    echo "$@" >&2
}

killer() {
    kill -- "$1"
    wait "$1"
}

rotate_log() {
    su-exec "$OWNER" savelog -c "$LOG_ROTATE_CYCLE" "$LOGFILE"
}

if [[ ! -x /sync.sh ]]; then
    log '/sync.sh not found'
    exit 1
fi

[[ $DEBUG = true ]] && set -x

[[ -z $OWNER ]] && export OWNER='0:0' # root:root
[[ -z $LOG_ROTATE_CYCLE ]] && export LOG_ROTATE_CYCLE=0

export TO=/data LOGDIR=/log
export LOGFILE="$LOGDIR/result.log"

[[ -x /pre-sync.sh ]] && . /pre-sync.sh

if [[ $LOG_ROTATE_CYCLE -ne 0 ]]; then
    trap 'rotate_log' EXIT
    su-exec "$OWNER" touch "$LOGFILE"
    su-exec "$OWNER" /sync.sh &> >(tee -a "$LOGFILE") &
else
    su-exec "$OWNER" /sync.sh &
fi
pid="$!"
trap 'killer $pid' INT HUP TERM
wait "$pid"

[[ -x /post-sync.sh ]] && . /post-sync.sh

exit 0
