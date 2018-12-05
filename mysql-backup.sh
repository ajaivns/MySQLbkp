#!/bin/bash

DTIME_NOW=`date +%Y-%m-%d_%H-%M-%S`
DST_DIR=/backup/NEOWEB-7/backup
ERROR_FLAG=0
ERROR_DBS=""
SERVER=NEOWEB7
LOG_DIR=/backup/bkp_logs/dbdumplogs
LOG_FILE=$LOG_DIR/tmp_log.txt
FINAL_LOG_FILE=$LOG_DIR/log_$DTIME_NOW.txt
MAILTOADDRS="backup-report@neotericuk.com"
#MAILTOADDRS="kurian@neotericuk.co.uk tech-support@neotericuk.co.uk asheesh@neotericuk.co.uk manish@neotericuk.co.uk vishal@neotericuk.com"
## MAILTOADDRS="kurian@neotericuk.co.uk"

mkdir -p $LOG_DIR;
mkdir -p $DST_DIR;cd $DST_DIR;
>$LOG_FILE

DBS=`mysql -u root --skip-column-names -e "show databases"`
DBS="$DBS"

for databs in `echo $DBS`
do
        mkdir -p $databs;
        pwd
        mysqldump -u root $databs >$databs/$databs-$DTIME_NOW.sql
        if [ $? = 0 ]
        then
                find $databs -type f -mtime +20 -exec rm -vf {} \;
                echo "Backup done -- $DST_DIR/$databs/$databs-$DTIME_NOW.sql.. Compressing" >>$LOG_FILE
                gzip $databs/$databs-$DTIME_NOW.sql
        else
                echo "Error while taking backup of $databs.. CRITICAL" >>$LOG_FILE      
                ERROR_FLAG=$[$ERROR_FLAG+1]
                ERROR_DBS="$ERROR_DBS $databs"
                echo "">>$LOG_FILE
        fi
done

if [ $ERROR_FLAG -eq 0 ]
then
        SUBJ="MySQL backup - $SERVER - Success"
        BODY="There are no errors while taking backup."

else
        SUBJ="MySQL backup - $SERVER - $ERROR_FLAG Failed"
        BODY="There are ERRORS. Could not take backup for $ERROR_DBS."
fi

cd /backup
(echo -e "$BODY\n\n"; cat $LOG_FILE) >$FINAL_LOG_FILE
cat $FINAL_LOG_FILE | mail -s "$SUBJ" "$MAILTOADDRS"
