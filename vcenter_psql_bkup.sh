#!/usr/bin/bash
#
# backup vCenter's Postgres database
# copyright (c) 2014 Pivotal Labs
#
# unlicense http://unlicense.org/

# source in EMB_DB_INSTANCE and EMB_DB_USER
. /etc/vmware-vpx/embedded_db.cfg

SQL_BKUP_FILE=vcenter_backup_$(date +%Y-%m-%d-%H:%M)
# exit early if backup files aleady exist
ls /tmp/$SQL_BKUP_FILE* && exit 2

# stop the vmware-vpxd for as little as possible
echo service vmware-vpxd stop
/opt/vmware/vpostgres/1.0/bin/pg_dump $EMB_DB_INSTANCE -U $EMB_DB_USER -Fp -c > /tmp/$SQL_BKUP_FILE.sql
echo service vmware-vpxd start

gzip /tmp/$SQL_BKUP_FILE.sql
