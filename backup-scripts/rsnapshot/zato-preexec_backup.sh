#!/bin/bash
#
#######################

ssh  -i /etc/rsnapshot/keys/rsnapshot_rsa root@10.10.11.1 /usr/local/sysadmin/preexec_backup.sh
