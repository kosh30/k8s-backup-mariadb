#!/usr/bin/env bash
BACKUP_DIR=$(dirname "$0")
DATE=$(date +%Y-%m-%d-%H%M)
if [ -z "$BACKUP_TYPE" ]; then
    BACKUP_TYPE=full
fi

if [ $BACKUP_TYPE = "full" ]; then
    TARGET_NAME_PREFIX=full
else
    TARGET_NAME_PREFIX=incremental
fi

cd "${BACKUP_DIR}" || exit

TARGET_NAME_FULL=${TARGET_NAME_PREFIX}.full
TARGET_NAME_INCREMENTAL=${TARGET_NAME_PREFIX}_${DATE}.inc

echo "Starting backup..."
echo $TARGET_NAME_FULL

full_backup() {
  START=$(date +%s)
  echo "Start full backup at ${START}"
    if [ -d ./${TARGET_NAME_FULL} ]; then
      rm -rf ./${TARGET_NAME_FULL}
    fi
    mkdir -p ./${TARGET_NAME_FULL}
    mariadb-backup --backup \
        --target-dir=./${TARGET_NAME_FULL}/data/ \
        --host="${DB_HOST}" \
        --port=3306 \
        --user="${DB_USER}" \
        --password="${DB_PASSWORD}" \
        2>&1 | tee -a ./${TARGET_NAME_FULL}/${TARGET_NAME_PREFIX}.log

    tar -cpzf ./${TARGET_NAME_FULL}.tar.gz ${TARGET_NAME_FULL}
    s5cmd cp ./${TARGET_NAME_FULL}.tar.gz "s3://${BUCKET_NAME}/${BACKUP_PREFIX}/${TARGET_NAME_FULL}.tar.gz"
    rm -rf ${TARGET_NAME_FULL}.tar.gz
    END=$(date +%s)
    echo "End full backup at ${END}"
}

full_backup

#incremental_backup() {
#    if [ ! -d "${TARGET_NAME_FULL}/data" ]; then
#        echo "No full backup found. Sync from s3"
#        s5cmd cp "s3://${S3_BUCKET}/${S3_PATH}/${TARGET_NAME_FULL}.tar.gz" ./
#    fi
#
#    if [ -d "./${TARGET_NAME_INCREMENTAL}" ]; then
#        rm -rf "./${TARGET_NAME_INCREMENTAL}"
#    fi
#
#    mkdir -p "./${TARGET_NAME_INCREMENTAL}"
#
#    echo "Start mariabackup utility..."
#
#    START=$(date +%s)
#
#    # Execute backup of db. Change options and credentials for mariabackup here
#    mariadb-backup --backup \
#        --target-dir=./${TARGET_NAME_INCREMENTAL}/data/ \
#        --incremental-basedir=${INCREMENTAL_BASE_DIR}/data/ \
#        --host="${DB_HOST}" \
#        --port=3306 \
#        --user="${DB_USER}" \
#        --password="${DB_PASSWORD}" \
#        2>&1 | tee -a ./${TARGET_NAME_INCREMENTAL}/${TARGET_NAME_PREFIX}.log
#}
#

#
#
#
#case ${ACTION} in
#    FULL)
#        if [ -d ./${TARGET_NAME_FULL} ]
#        then
#            printf "Directory ${BACKUP_DIR}/${TARGET_NAME_FULL} already exists. No full backup was created!\n"
#            exit 3
#        fi
#
#        mkdir -p ./${TARGET_NAME_FULL}
#
#        printf "Start mariabackup utility...\n"
#
#        START=$(date +%s)
#
#        # Execute backup of db. Change options and credentials for mariabackup here
#        mariabackup --backup \
#            --target-dir=./${TARGET_NAME_FULL}/data/ \
#            --host=127.0.0.1 \
#            --port=3306 \
#            --user=backup \
#            >> ./${TARGET_NAME_FULL}/${TARGET_NAME_PREFIX}.log 2>&1
#
#        BACKUP_RETURNSTATE=$?
#        END=$(date +%s)
#
#        printf "\n----------------------------------------\n\n" >> ./${TARGET_NAME_FULL}/${TARGET_NAME_PREFIX}.log
#        printf "Execution date:      ${DATE}\n" >> ./${TARGET_NAME_FULL}/${TARGET_NAME_PREFIX}.log
#        printf "Backup runtime:      $((END-START))s\n" >> ./${TARGET_NAME_FULL}/${TARGET_NAME_PREFIX}.log
#
#        if [ ${BACKUP_RETURNSTATE} -ne 0 ]
#        then
#            printf "Failed to create full backup. Check ${BACKUP_DIR}/${TARGET_NAME_FULL}/${TARGET_NAME_PREFIX}.log\n"
#            exit 5
#        fi
#
#        printf "Full backup created in: ${BACKUP_DIR}/${TARGET_NAME_FULL}\n"
#        printf "Compressing files...\n"
#
#        # Pack new backup files to .tar.gz
#        tar -cpzf ${TARGET_NAME_FULL}.tar.gz ${TARGET_NAME_FULL}
#
#        # Remove folders with full backup except newly created folder
#        find ./${TARGET_NAME_PREFIX}_*.full -maxdepth 0 -type d -not -name ${TARGET_NAME_FULL} -exec rm -r {} \;
#
#        printf "Tar-Archive created: ${BACKUP_DIR}/${TARGET_NAME_FULL}.tar.gz.\n"
#        ;;
#    INCREMENTAL)
#        if [ -z ${INCREMENTAL_BASE_DIR} ] || [ ! -d ${INCREMENTAL_BASE_DIR} ]
#        then
#            printf "No base dir for incremental backup found\n"
#            exit 4
#        fi
#
#        if [ -d ./${TARGET_NAME_INCREMENTAL} ]
#        then
#            printf "Directory ${BACKUP_DIR}/${TARGET_NAME_INCREMENTAL} already exists. No incremental backup was created!\n"
#            exit 3
#        fi
#
#        mkdir -p ./${TARGET_NAME_INCREMENTAL}
#
#        printf "Start mariabackup utility...\n"
#
#        START=$(date +%s)
#
#        # Execute backup of db. Change options and credentials for mariabackup here
#        mariabackup --backup \
#            --target-dir=./${TARGET_NAME_INCREMENTAL}/data/ \
#            --incremental-basedir=${INCREMENTAL_BASE_DIR}/data/ \
#            --host=127.0.0.1 \
#            --port=3306 \
#            --user=backup \
#            >> ./${TARGET_NAME_INCREMENTAL}/${TARGET_NAME_PREFIX}.log 2>&1
#
#        BACKUP_RETURNSTATE=$?
#        END=$(date +%s)
#
#        printf "\n----------------------------------------\n\n" >> ./${TARGET_NAME_INCREMENTAL}/${TARGET_NAME_PREFIX}.log
#        printf "Execution date:      ${DATE}\n" >> ./${TARGET_NAME_INCREMENTAL}/${TARGET_NAME_PREFIX}.log
#        printf "Backup runtime:      $((END-START))s\n" >> ./${TARGET_NAME_INCREMENTAL}/${TARGET_NAME_PREFIX}.log
#        printf "Incremental basedir: `basename ${INCREMENTAL_BASE_DIR}`\n" >> ./${TARGET_NAME_INCREMENTAL}/${TARGET_NAME_PREFIX}.log
#
#        if [ ${BACKUP_RETURNSTATE} -ne 0 ]
#        then
#            printf "Failed to create incremental backup. Check ${BACKUP_DIR}/${TARGET_NAME_INCREMENTAL}/${TARGET_NAME_PREFIX}.log\n"
#            exit 5
#        fi
#
#        printf "Incremetal backup created in: ${BACKUP_DIR}/${TARGET_NAME_INCREMENTAL}\nBase dir used: ${INCREMENTAL_BASE_DIR}\n"
#        printf "Compressing files...\n"
#
#        # Pack new backup files to .tar.gz
#        tar -cpzf ${TARGET_NAME_INCREMENTAL}.tar.gz ${TARGET_NAME_INCREMENTAL}
#
#        # Remove folders with incremental backup
#        find ./${TARGET_NAME_PREFIX}_*.inc -maxdepth 0 -type d -exec rm -r {} \;
#
#        printf "Tar-Archive created: ./${TARGET_NAME_INCREMENTAL}.tar.gz and folder removed.\n"
#        ;;
#esac
#
## Copy all backuped files to remote location
## Files are defined in temporary .export file
#
#printf "Move backups to storage destination...\n"
#
#find ./${TARGET_NAME_PREFIX}_*.tar.gz -maxdepth 0 -type f | sort -nr > ./.export
#rsync --times --protect-args --remove-source-files --files-from=./.export . ${STORAGE_DEST}
#
#RSYNC_RETURNSTATE=$?
#
## Remove temporary .export file
#rm ./.export
#
#if [ ${RSYNC_RETURNSTATE} -ne 0 ]
#then
#    printf "Failed to move (some) backups to ${STORAGE_DEST}\n"
#    exit 6
#else
#    printf "Backups moved to ${STORAGE_DEST}\n"
#    exit 0
#fi