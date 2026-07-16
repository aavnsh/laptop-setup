#!/bin/sh

# Saved in ~/online-check.sh and in a cron job as:
# * * * * * ~/online-check.sh

# An online indicator, green for active connection, and red for not.
# It's done by a cronjob touching or removing a file to indicate
# status every minute, and the file is checked by the prompt.

offline=`dig 8.8.8.8 +time=1 +short google.com A | grep -c "no servers could be reached"`
if [[ "$offline" == "0" ]]; then
  echo 'online'
  if [ -f '/tmp/.offline' ]; then
    rm /tmp/.offline
  fi
else
  echo 'offline'
  touch /tmp/.offline
fi