#!/bin/bash

stop()
{
  # We're here because we've seen SIGTERM, likely via a Docker stop command or similar
  # Let's shutdown cleanly
  echo "SIGTERM caught, terminating NFS process(es)..."
  /usr/sbin/exportfs -uav
  /usr/sbin/rpc.nfsd 0
  pid1=`pidof rpc.nfsd`
  pid2=`pidof rpc.mountd`
  # For IPv6 bug:
  pid3=`pidof rpcbind`
  kill -TERM $pid1 $pid2 $pid3 > /dev/null 2>&1
  echo "Terminated."
  exit
}

add_line_to_etc_exports()
{
    # declare read-only variables
    declare -r nr=$1
    declare -r dir=$2
    declare fsid=""

    if [ $nr -eq 1 ]
    then
        fsid=",fsid=0"
    fi
    
    echo "Writing ${dir} to /etc/exports file, line ${nr}"
    echo "${dir} ${PERMITTED}(${READ_ONLY},${SYNC},no_subtree_check,no_auth_nlm,insecure,no_root_squash${fsid})" >> /etc/exports
}

create_etc_exports()
{
    # set error checking on
    set -e
    
    test ! -f /etc/exports || rm /etc/exports

    # Check if the PERMITTED variable is empty
    if [ -z "${PERMITTED}" ]; then
        echo "The PERMITTED environment variable is unset or null, defaulting to '*'."
        echo "This means any client can mount."
        PERMITTED='*'
    else
        echo "The PERMITTED environment variable is set."
        echo "The permitted clients are: ${PERMITTED}."
    fi

    # Check if the READ_ONLY variable is set (rather than a null string) using parameter expansion
    if [ -z ${READ_ONLY+y} ]; then
        echo "The READ_ONLY environment variable is unset or null, defaulting to 'rw'."
        echo "Clients have read/write access."
        READ_ONLY=rw
    else
        echo "The READ_ONLY environment variable is set."
        echo "Clients will have read-only access."
        READ_ONLY=ro
    fi

    # Check if the SYNC variable is set (rather than a null string) using parameter expansion
    if [ -z "${SYNC+y}" ]; then
        echo "The SYNC environment variable is unset or null, defaulting to 'async' mode".
        echo "Writes will not be immediately written to disk."
        SYNC=async
    else
        echo "The SYNC environment variable is set, using 'sync' mode".
        echo "Writes will be immediately written to disk."
        SYNC=sync
    fi
    
    # Check if the SHARED_DIRECTORY variable is empty
    if [ -z "${SHARED_DIRECTORY}" ]; then
        echo "The SHARED_DIRECTORY environment variable is unset or null, exiting..."
        exit 1
    elif [ ! -d "${SHARED_DIRECTORY}" ]; then
        echo "The directory '${SHARED_DIRECTORY}' does not exist, exiting..."
        exit 1
    fi

    # Add root directory ${SHARED_DIRECTORY} and its subfolders to the /etc/exports
    
    declare nr=1
    
    add_line_to_etc_exports $nr ${SHARED_DIRECTORY}

    for dir in $(ls -1 ${SHARED_DIRECTORY})
    do
        if [ -d "${SHARED_DIRECTORY}/$dir" ]
        then
            nr=$(expr $nr + 1)
            add_line_to_etc_exports $nr "${SHARED_DIRECTORY}/$dir"
        fi
    done

    # set error checking off
    set +e
}

run()
{
    # Partially set 'unofficial Bash Strict Mode' as described here: http://redsymbol.net/articles/unofficial-bash-strict-mode/
    # We don't set -e because the pidof command returns an exit code of 1 when the specified process is not found
    # We expect this at times and don't want the script to be terminated when it occurs
    set -uo pipefail
    IFS=$'\n\t'

    # This loop runs till until we've started up successfully
    while true; do

        # Check if NFS is running by recording it's PID (if it's not running $pid will be null):
        pid=`pidof rpc.mountd`

        # If $pid is null, do this to start or restart NFS:
        while [ -z "$pid" ]; do
            echo "Displaying /etc/exports contents:"
            cat /etc/exports
            echo ""

            # Normally only required if v3 will be used
            # But currently enabled to overcome an NFS bug around opening an IPv6 socket
            echo "Starting rpcbind..."
            /sbin/rpcbind -w
            echo "Displaying rpcbind status..."
            /sbin/rpcinfo

            # Only required if v3 will be used
            # /usr/sbin/rpc.idmapd
            # /usr/sbin/rpc.gssd -v
            # /usr/sbin/rpc.statd

            echo "Starting NFS in the background..."
            /usr/sbin/rpc.nfsd --debug 8 --no-udp --no-nfs-version 2 --no-nfs-version 3
            echo "Exporting File System..."
            if /usr/sbin/exportfs -rv; then
                /usr/sbin/exportfs
            else
                echo "Export validation failed, exiting..."
                exit 1
            fi
            echo "Starting Mountd in the background..."These
            /usr/sbin/rpc.mountd --debug all --no-udp --no-nfs-version 2 --no-nfs-version 3
            # --exports-file /etc/exports

            # Check if NFS is now running by recording it's PID (if it's not running $pid will be null):
            pid=`pidof rpc.mountd`

            # If $pid is null, startup failed; log the fact and sleep for 2s
            # We'll then automatically loop through and try again
            if [ -z "$pid" ]; then
                echo "Startup of NFS failed, sleeping for 2s, then retrying..."
                sleep 2
            fi

        done

        # Break this outer loop once we've started up successfully
        # Otherwise, we'll silently restart and Docker won't know
        echo "Startup successful."
        break

    done

    while true; do

        # Check if NFS is STILL running by recording it's PID (if it's not running $pid will be null):
        pid=`pidof rpc.mountd`
        # If it is not, lets kill our PID1 process (this script) by breaking out of this while loop:
        # This ensures Docker observes the failure and handles it as necessary
        if [ -z "$pid" ]; then
            echo "NFS has failed, exiting, so Docker can restart the container..."
            break
        fi

        # If it is, give the CPU a rest
        sleep 1

    done
}

# -----------
# Main starts
# -----------

# Make sure we react to these signals by running stop() when we see them - for clean shutdown
# And then exiting
trap "stop; exit 0;" SIGTERM SIGINT

if [ -r /etc/exports -a ! -w /etc/exports ]
then
    echo "A read-only /etc/exports exists so will not overwrite that one"
else
    create_etc_exports  
fi

run

sleep 1
exit 1
