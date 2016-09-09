#!/bin/bash
#
# Will print csv:
# ReportDate,hostname,version,enabled,lastapply
# e.g.
# 2016-09-07,123456-host.example.com,v0.7,Enabled,Aug 31 17:30:13
#

#set -x
#Function to print usage
function print_usage {
echo
echo "Usage: $scriptname [FLAGS]"
echo
echo "Supported FLAGS:"
echo -e " -c, --csv \t Output as csv"
echo -e " -h, --help  \t print this help message"
echo
exit 1
}

OUTPUT="detailed"

OPTS=$(getopt -o O:c,h --long csv,help -- "$@")
eval set -- "$OPTS"

# Extract options and their arguments into variables.
while true; do
case "$1" in
--csv|-c) OUTPUT="csv"; shift;;
--help|-h) print_usage; shift;;
--) shift ; break ;;
esac
done

function print_report() {
  if [[ ${OUTPUT} == "csv" ]]; then
    # Print CSV
    echo
    echo "CSV:"
    echo -e "Hostname,Version,Status,LastUpdate"
    echo "${hostname},v${version},$([[ ${enabled} == "YES" ]] && echo "Enabled" || echo "Disabled"),${lastapply}"
    echo
  fi

  if [[ ${OUTPUT} == "detailed" ]]; then
    # Print in a readable format
    echo
    echo -e "Auter schedule for $(hostname) on $(date):"
    echo "Device Number: ${devicenumber}"
    echo "Version : ${version}"
    echo "Enabled : ${enabled}"
    echo "Last run: ${lastapply}"
    echo "pre_apply_scripts:${pre_apply_scripts}"
    echo "post_appy_scripts:${post_apply_scripts}"
    echo "pre_reboot_scripts:${pre_reboot_scripts}"
    echo "post_reboot_scripts:${post_reboot_scripts}"

    echo "Schedule:"
    echo "${schedule}" | sed 's/^/\t/g'
    echo
  fi

  if [[ $SIMPLE ]]; then
    echo -e "\n\nSimple output:"
    echo -e "$(hostname)%${version}%$([[ ${enabled} == "YES" ]] && echo "Enabled" || echo "Disabled")%${lastapply}" | column -s "%" -t 
  fi
}

function print_schedule(){
  if [[ "$(whoami)" != "root" ]]; then
    echo "To see the schedule Please run this as root"
  else
    for usercron in $(awk -F: '{print $1}' /etc/passwd); do
      crontab -u $usercron -l 2>/dev/null| grep auter
    done

    if [[ -f /usr/bin/atq ]]; then
      for userat in $(atq | cut -f 1); do
        at -c "$userat" | grep auter
      done
    fi

    grep -r auter /etc/cron* /var/spool/cron/ | egrep -v ":#|rpm"
  fi
}

hostname=$(hostname)
installed=0
version="NOT INSTALLED"
enabled="N/A"
schedule="N/A"
lastapply="N/A"
pre_apply_scripts="NONE"
post_appy_scripts="NONE"
pre_reboot_scripts="NONE"
post_reboot_scripts="NONE"

# Check if RPM is installed
if ! rpm -q auter &>/dev/null; then
  print_report
  exit 0
fi

# Get version
version=$(auter --version | awk '{print $2}')

# Get auter state
if auter --status | grep "auter.*enabled" &>/dev/null; then
  enabled=YES
else
  enabled=NO
fi

# Get cron schedule
schedule=$(print_schedule | column -t)

# Get last apply time
for MESSAGES in $(ls -1t /var/log/messages*);do
  if [[ $(zgrep -c "auter.*complete" ${MESSAGES}) > 0 ]]; then
    lastapply=$(zgrep "auter.*complete" ${MESSAGES} | tail -1 | awk '{print $1,$2,$3}')
    break
  fi
done

if [[ $(echo ${version} | awk -F "." '{print $2}') -lt 7 ]]; then
  SCRIPTDIR="/var/lib/auter"
else
  SCRIPTDIR="/etc/auter"
fi

if [[ -d ${SCRIPTDIR}/pre-apply.d ]];then
  pre_apply_scripts=$(for file in $(ls -1 ${SCRIPTDIR}/pre-apply.d); do echo -en "\n\t\t- ${SCRIPTDIR}/pre-apply.d/${file} ";done)
  [[ ${pre_apply_scripts} == "" ]] && pre_apply_scripts="NONE"
fi

if [[ -d ${SCRIPTDIR}/post-apply.d ]];then
  post_apply_scripts=$(for file in $(ls -1 ${SCRIPTDIR}/post-apply.d); do echo -en "\n\t\t- ${SCRIPTDIR}/post-apply.d/${file} ";done)
  [[ ${post_apply_scripts} == "" ]] && post_apply_scripts="NONE"
fi

if [[ -d ${SCRIPTDIR}/pre-reboot.d ]];then
  pre_reboot_scripts=$(for file in $(ls -1 ${SCRIPTDIR}/pre-reboot.d); do echo -en "\n\t\t- ${SCRIPTDIR}/pre-reboot.d/${file} ";done)
  [[ ${pre_reboot_scripts} == "" ]] && pre_reboot_scripts="NONE"
fi

if [[ -d ${SCRIPTDIR}/post-reboot.d ]];then
  post_reboot_scripts=$(for file in $(ls -1 ${SCRIPTDIR}/post-reboot.d); do echo -en "\n\t\t- ${SCRIPTDIR}/post-reboot.d/${file} ";done)
  [[ ${post_reboot_scripts} == "" ]] && post_reboot_scripts="NONE"
fi

print_report
