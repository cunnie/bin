#!/bin/bash
#
# backup vCenter's Postgres database
# copyright (c) 2014 Pivotal Labs
#
# License: unlicense http://unlicense.org/
#
if [ $# -ne 2 ]; then
    echo "Usage: $0 S3-bucket-name file-prefix"
    echo "e.g."
    echo "  $0 vcenter.cf.nono.com vcenter_bkup"
    exit 2
fi

S3_BUCKET_NAME=$1
SQL_BKUP_FILE=$2_$(date +%Y-%m-%d-%H:%M)

# source in EMB_DB_INSTANCE and EMB_DB_USER
. /etc/vmware-vpx/embedded_db.cfg

# exit early if backup files aleady exist
ls /tmp/$SQL_BKUP_FILE* > /dev/null 2>&1 && exit 2

# stop the vmware-vpxd for as briefly as possible
service vmware-vpxd stop > /dev/null 2>&1
/opt/vmware/vpostgres/1.0/bin/pg_dump $EMB_DB_INSTANCE -U $EMB_DB_USER -Fp -c > /tmp/$SQL_BKUP_FILE.sql
service vmware-vpxd start > /dev/null 2>&1

gzip /tmp/$SQL_BKUP_FILE.sql
if /usr/local/sbin/s3cmd-1.0.1/s3cmd put /tmp/$SQL_BKUP_FILE.sql.gz s3://$S3_BUCKET_NAME/ > /dev/null 2>&1; then
	:
else
	echo "S3 upload failed!"
	exit 3
fi
