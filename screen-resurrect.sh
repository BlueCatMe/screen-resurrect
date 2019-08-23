#!/bin/sh

#######################
# Usage
usage() {
  echo "USAGE: ${0} -b | -r [backup_number]"
  exit 1
}

#######################
# Config Variables
max_win=15
max_backups=12
ignore_sessions="hosts"
backup_dir=~/.screen-resurrect/snapshot

#######################
# Use info line to get state of window.
get_state() {
   info_pattern='^ScreenWindowDump=.*@.*:'
   info_line=$(grep -a "$(eval echo ${info_pattern})" ${window_full} | tail -n 1)
   info_line=$(printf "${info_line}" | cut -d= -f2)
   user=$(printf "${info_line}" | cut -d@ -f1)
   host=$(printf "${info_line}" | cut -d@ -f2 | cut -d: -f1)
   working_dir=$(printf "${info_line}" | cut -d: -f2 | cut -d$ -f1)
}

#######################
# Code
if [ ! ${1} ] ;then
  usage
fi

while [ ${1} ] ;do
  case ${1} in
    -b)
      task=backup
      shift 1
    ;;
    -r)
      task=restore
      if [ ${2} ] ;then
        backup_number=${2}
        shift 2
      else
        shift 1
      fi
    ;;
    *)
      usage
    ;;
  esac
done

if [ "${task}" = 'backup' ] ;then
  ##Rotate previous backups.
  i=${max_backups}
  while [[ ${i} != 0 ]] ;do
    if [ -d ${backup_dir}.${i} ] ;then
      if [[ ${i} = ${max_backups} ]] ;then
        rm -r ${backup_dir}.${i}
      else
        mv ${backup_dir}.${i} ${backup_dir}.$((${i}+1))
      fi
    fi
    i=$((${i}-1))
  done
  if [ -d ${backup_dir} ] ;then
    mv ${backup_dir} ${backup_dir}.1
  fi

  ##Dump hardcopy from all windows in all available screen sessions.
  if [ ! -d ${backup_dir} ] ;then
    mkdir -p ${backup_dir}
  fi
  for session_dir in $(screen -ls | grep tached\)$ | awk '{print $1}') ;do
    session=$(echo ${session_dir} | cut -d. -f2)
    for ignore_session in ${ignore_sessions} ;do
      if [ ${session} = ${ignore_session} ] ;then
        continue 2
      fi
    done
    if [ ! -d ${backup_dir}/${session_dir} ] ;then
      mkdir -p ${backup_dir}/${session_dir}
    fi
    for win in $(seq 0 $max_win) ;do
      window=${backup_dir}/${session_dir}/${win}
      screen -S ${session_dir} -p ${win} -X stuff $"\032\n\n"
      screen -S ${session_dir} -p ${win} -X hardcopy -h ${window}
      screen -S ${session_dir} -p ${win} -X stuff "eval \"echo ScreenWindowDump=\`whoami\`@\`hostname\`:\`pwd\` >> ${window}\"\n"
      screen -S ${session_dir} -p ${win} -X stuff $"fg\n"
      if [ ! -s ${window} ] ;then
        sleep 1
        rm -rf ${window}
      fi
    done
  done

elif [ "${task}" = 'restore' ] ;then

  ##Check for specified number backup.  If none, then use latest.
  if [ "${backup_number}" != '' ] ;then
    backup_dir=${backup_dir}.${backup_number}
  fi

  ##Restore sessions and windows from backups.
  for session_dir in $(ls ${backup_dir}) ;do
    session_full=${backup_dir}/${session_dir}
    session=$(echo ${session_dir} | cut -d. -f2)
    screen -d -m -S ${session}
    i=0
    for window in $(ls ${session_full}) ;do
      window_full=${session_full}/${window}
      get_state
      echo "${session}:${window}:${user}@${host}:${working_dir}"
      if [ ${window} -ne 0 ] ;then
        screen -S ${session} -p \- -X screen
        screen -S ${session} -p ${i} -X number ${window}
      fi
      screen -S ${session} -p ${window} -X stuff "cat ${window_full}\n"
      if [ "${host}" != "$(hostname)" ] ;then
        screen -S ${session} -p ${window} -X stuff "ssh ${host}\n"
        sleep 2
      fi
      screen -S ${session} -p ${window} -X stuff "cd ${working_dir}\n"
      if [ ${window} -eq ${i} ] ;then
        i=$((${i}+1))
      fi
    done
  done

fi
