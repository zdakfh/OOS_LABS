#!/bin/bash

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S')]: $*" >&2
}

check() {
	if [ "$1" -ne 0 ]; then
		err ${@:3}
		exit
	else
		echo "$2"
	fi
}


getunit() {
	tmp=$(systemctl status "$1" | grep loaded | head -1)
	local path=$(awk '{ sub(/.*\(/, ""); sub(/;.*/, ""); print }' <<< $tmp)
	echo "$path"
}

getextraperms() {
    getfacl $1 2>/dev/null | grep -v -E "^#" | grep -v "user::" | grep -E ":.w.$"
}

services=$(systemctl list-units --type=service | tail -n +2 | head -n -7 | cut -c 3- | cut -d ' ' -f 1)

for service in $services; do
    unitpath=$(getunit $service)
    perms=$(getextraperms $unitpath)
    if [ -n "$perms" ]; then
        echo "$service has a unit ($unitpath) with extra write permissions:"
        echo "  $perms"
    fi
    user=$(grep "User=" "$unitpath")

    readarray -t execs < <(grep -E "(ExecStart|ExecStartPre|ExecStartPost|ExecReload|ExecStop|ExecStopPost)=" "$unitpath")
    for directive in "${execs[@]}"; do
        execommand="${directive#*=}"
        executable=$(cut -f1 -d" " <<< "$execommand")
        executable="${executable/#-/}" # remove first -
        executableperms=$(getextraperms $executable)
        if [ -n "$executableperms" ]; then
            echo "$service has a directive (in $unitpath) with extra write permissions"
            echo "  directive: $directive"
            echo "  extra permissions: $executableperms"
        fi

        if [ ! "$user" = "User=root" ]; then
            owner=$(stat -c '%U' "$executable")
            if [ "$owner" = "root" ]; then
                if stat -L -c "%A" "$executable" | grep -q "s"; then
                    echo "$service is run under $user but has a directive (in $unitpath) with suid/guid executable owned by root"
                    echo "  directive: $directive"
                fi
            fi
        fi
    done
done
