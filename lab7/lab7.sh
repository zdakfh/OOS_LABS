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

readinput() {
	local -n list=$1
	list+=("Справка" "Выход")
	select opt in "${list[@]}"; do
	case $opt in
		Выход) return 0;;
		Справка) echo "$2";;
		*)
			if [[ -z $opt ]]; then
				echo "Ошибка: введите число из списка" >&2
			else
				return "$REPLY"
			fi
			;;
	esac
	done
}

if [ "$EUID" -ne 0 ]; then
	echo "Permission denied, запустите программу c правами администратора"
	exit
fi

if [ "$1" = "--help" ]; then
	echo 'Лабораторная работа "Управление файловыми системами"

'
	exit
fi

PS3=$'\n> '
options=(
	"Вывести таблицу файловых систем"
	"Монтировать файловую систему"
	"Отмонтировать файловую систему"
	"Изменить параметры монтирования примонтированной файловой системы"
	"Вывести параметры монтирования примонтированной файловой системы"
	"Вывести детальную информацию о файловой системе ext*"
	"Справка"
	"Выйти"
)

select opt in "${options[@]}"
do
	case $opt in
	"Вывести таблицу файловых систем")
		df -x proc -x sys -x tmpfs -x devtmpfs --output=source,fstype,target
		;;

	"Монтировать файловую систему")
		read -r -p "Введите путь до файла/устройства: " filepath
		if [ ! -b "$filepath" ] && [ ! -f "$filepath" ]; then
			err "not exist or not a blockdevice|file"
			continue
		fi

		read -r -p "Введите каталог монтирования: " mountpath

		if [ ! -e "$mountpath" ]; then
			mkdir "$mountpath"
			if [ $? -ne 0 ]; then
				err "creating $mountpath"
				exit
			fi
		fi
		
		if [ -d "$mountpath" ]; then
			if [ -z "$(ls -A "$mountpath")" ]; then
				#err "dir exists and empty"
				:
			else
				err "dir exists and not empty"
				continue
			fi
		else
			err "Not a directory"
			continue
		fi

		if [ -f "$filepath" ]; then
			device=$( sudo losetup --find --show "$filepath")
			mount "$device" "$mountpath"
		else
			echo success
			mount "$filepath" "$mountpath"
		fi
		check $? "Успешно примонтировано" "Ошибка монтирования"
		;;
	"Отмонтировать файловую систему")
		read -r -p "Введите путь до файловой системы (пропустите для списка): " filesyspath
		if [ -z "$filesyspath" ]; then
			readarray -t mounts < <(df -x proc -x sys -x tmpfs -x devtmpfs --output=target | tail -n +2)
			listselect mounts "Введите число, соответствующее папке, которую хотите отмонтировать"
			res=$?
			[ $res == 0 ] && continue
			filesyspath=${mounts[res - 1]}
		fi
		if [ -n "$filesyspath" ]; then
			umount "$filesyspath"
			check $? "Успешно отмонтировано" "Ошибка отмнотирования"
		fi
		;;

	"Изменить параметры монтирования примонтированной файловой системы")
	  read -r -p "Введите путь до файловой системы: " remountfilesyspath
		if [ -z "$remountfilesyspath" ]; then
			readarray -t mounts < <(printblockdevices)
			readinput mounts
			res=$?
			[ $res == 0 ] && continue
			remountfilesyspath=$(echo ${mounts[res - 1]} | cut -d " " -f3 )
		fi

	    chooseopt=("только чтение" "чтение и запись")
		readinput chooseopt
		res=$?
		if [ $res == 1 ]; then
	    	mount -o remount,ro $remountfilesyspath
	    else
            mount -o remount,rw $remountfilesyspath
		fi
        ;;
	"Вывести параметры монтирования примонтированной файловой системы")
		readarray -t mounts < <(df -x proc -x sys -x tmpfs -x devtmpfs --output=target | tail -n +2)
		listselect mounts "Введите число, соответствующее папке, параметры которой хотите изменить"
		res=$?
		[ $res == 0 ] && continue
		filesyspath=${mounts[res - 1]}
		if [ -n "$filesyspath" ]; then
			mount | grep "$filesyspath"
		fi
		;;
 	"Вывести детальную информацию о файловой системе ext*")
		echo "Имеются следующие файловые системы ext*:"
		readarray -t exts < <(df -t ext2 -t ext3 -t ext4 -t extcow --output=source,target | tail -n +2 | sed "s/ \+/ on /g")
		readarray -t devices < <(df -t ext2 -t ext3 -t ext4 -t extcow --output=source | tail -n +2)
		listselect exts "Введите число, соответствующее интересующей файловой системе"
		res=$?
		[ $res == 0 ] && continue
		device=${devices[res - 1]}
		tune2fs -l $device | tail -n +2
		;;
	"Справка")
		echo "Введите интересующую вас команду"
		;;
	"Выйти")
		break
		;;
	*) echo "Неправильная команда $REPLY";;
	esac
done
