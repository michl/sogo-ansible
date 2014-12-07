#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
INIF=$(dirname $0)/config.ini
[ ! -f $INIF ] && echo "Missing INI file" && exit 1
. $INIF

echo "'$1''$2'" | logger -t QUOTA

[ "$2" ] || exit 1

PERC="$1"
U="$2"

MAIL=`ldapsearch -D $BDN -w $APW -b $OU "sAMAccountName=$U" | egrep -e ^mail:\  | cut -d' ' -f 2`
NAME=`ldapsearch -D $BDN -w $APW -b $OU "sAMAccountName=$U" | egrep -e ^displayName: | cut -d':' -f 2-`
QUOT=`ldapsearch -D $BDN -w $APW -b $OU "sAMAccountName=$U" | egrep -e ^maxStorage: | cut -d':' -f 2-`
FCHR=`echo "$NAME" | colrm 2`
[ "$FCHR" == ":" ] && NAME=" `echo "$NAME" | cut -d' ' -f 2- | base64 -d`"

if [ "$MAIL" ]; then
  case "$PERC" in
    "below")
        TXT="Dear$NAME,

Your mailbox size is smaller than the 80 percent of your limit again.

For your information: your quota limit is $QUOT Megabytes.

Regards,

$MMDOM mail administration"
        SUB="Quota warning has gone"
        ;;
    "80"|"95")
        TXT="Dear$NAME,

Your mailbox size is under quota, and you reached the $PERC percent 
of this limit.

ATTENTION: If you reached the maximum limit, you cannot send or receive 
any email!

Please delete some messages from your mail folders and subfolders, which 
aren't need for you anymore, or archieve them.
Please empty the deleted items folder too.

Reminder: your quota limit is $QUOT Megabytes.

Regards,

$MMDOM mail administration"
        SUB="[URGENT] Quota warning - $PERC%"
        ;;
esac

if [ $PERC == "95" ]; then
  TXT=$(echo "$TXT" | sed 's/Regards,.*/*WARNING: if you ignore this mail, you won't receive quota warnings anymore, \nso your mail system will be stucked!*\n\n&/')
fi
  echo "From: $CEM
To: $MAIL
Subject: =?UTF-8?B?$(echo -n "$SUB" | base64)?=
Content-Type: text/plain; charset=\"UTF-8\"
Content-Transfer-Encoding: 8bit

$TXT
" | sendmail -f $CEM $MAIL
fi
