#!/bin/bash
#
# backup vCenter's Postgres
# and inventory services databases
#
# vcenter_db_bkup.sh S3_bucket_name
#
# Intended use: to be executed by an entry in /etc/crontab. For
# example, the following entry would kick off a backup at at 10:25 a.m.
# UTC (i.e. 3:25 a.m. PDT)
#
#   25 10 * * *   root  /usr/local/sbin/vcenter_db_bkup.sh S3_bucket_name
#
# copyright (c) 2014 Pivotal Labs
#
# License: unlicense http://unlicense.org/
#
# Successful operation is silent so as to not generate emails that
# clutter root's mailbox with cron email.

# Make sure you set your S3 bucket name!
S3_BUCKET_NAME=PLACEHOLDER_FOR_S3_BUCKET_NAME

if [ $# -eq 1 ]; then
  S3_BUCKET_NAME=$1
fi

DATE=$(date +%Y-%m-%d-%H:%M)
PG_BKUP_FILE=postgres_$DATE
IS_BKUP_FILE=inventory_services_$DATE

# source in EMB_DB_INSTANCE and EMB_DB_USER
. /etc/vmware-vpx/embedded_db.cfg

# exit early if backup files already exist
ls /tmp/$PG_BKUP_FILE* > /dev/null 2>&1 && exit 2

# stop the vmware-vpxd for as briefly as possible, backup up postgres
# http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2034505
service vmware-vpxd stop > /dev/null 2>&1
/opt/vmware/vpostgres/1.0/bin/pg_dump $EMB_DB_INSTANCE -U $EMB_DB_USER -Fp -c > /tmp/$PG_BKUP_FILE.sql
service vmware-vpxd start > /dev/null 2>&1

# stop the vmware-inventoryservice for as briefly as possible, backup up DB
# http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2062682
service vmware-inventoryservice stop > /dev/null 2>&1
cd /usr/lib/vmware-vpx/inventoryservice/scripts/
./backup.sh -file /tmp/$IS_BKUP_FILE.DB > /dev/null 2>&1
service vmware-inventoryservice start > /dev/null 2>&1

# zip 'em up
gzip /tmp/$PG_BKUP_FILE.sql
gzip /tmp/$IS_BKUP_FILE.DB

# upload 'em
/usr/local/sbin/s3cmd-1.0.1/s3cmd put /tmp/$PG_BKUP_FILE.sql.gz s3://$S3_BUCKET_NAME/ > /dev/null 2>&1
rc_pg=$?
/usr/local/sbin/s3cmd-1.0.1/s3cmd put /tmp/$IS_BKUP_FILE.DB.gz  s3://$S3_BUCKET_NAME/ > /dev/null 2>&1
rc_is=$?

# are we cool?
if [ $rc_is -ne 0 ] || [ $rc_pg -ne 0 ]; then
   echo "S3 upload failed!"
   exit 3
fi
