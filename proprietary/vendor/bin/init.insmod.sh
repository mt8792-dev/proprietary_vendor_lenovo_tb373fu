#!/vendor/bin/sh

########################################################
### init.insmod.cfg format:                          ###
### -----------------------------------------------  ###
### [insmod|setprop|enable/moprobe] [path|prop name] ###
### ...                                              ###
########################################################

if [ $# -eq 1 ]; then
  cfg_file=$1
else
  exit 1
fi

if [ -f $cfg_file ]; then
  while IFS="|" read -r action arg
  do
    case $action in
      "insmod") insmod $arg ;;
      "setprop")
        times=1
        setprop $arg 1
        while [ "$?" -ne 0 ]
        do
          if [ $times -gt 128 ]; then
            break
          fi
          let times++
          setprop $arg 1
        done ;;
      "enable") echo 1 > $arg ;;
      "modprobe")
        insmod_arg=${arg}
        for partition in system_dlkm vendor
        do
          case ${insmod_arg} in
            "-b *" | "-b")
              arg="-b $(cat /${partition}/lib/modules/modules.load)" ;;
            "*" | "")
              arg="$(cat /${partition}/lib/modules/modules.load)" ;;
          esac
          arg="$(echo ${arg} | sed -e 's/zram\.ko//g')"
          arg="$(echo ${arg} | sed -e 's/zram_ext\.ko//g')"
          arg="$(echo ${arg} | sed -e 's/extend_reclaim\.ko//g')"
          modprobe -a -d /${partition}/lib/modules $arg
        done
        if [ -f "/vendor/lib/modules/zram_ext.ko" ] && [ -f "/vendor/lib/modules/extend_reclaim.ko" ]; then
            insmod  /vendor/lib/modules/zram_ext.ko
            insmod  /vendor/lib/modules/extend_reclaim.ko

        elif [ -f "/system_dlkm/lib/modules/zram.ko" ];then
            insmod /system_dlkm/lib/modules/zram.ko
        else
            echo "zram error!"
        fi
    esac
  done < $cfg_file
else
  exit 2
fi

