

CURRENT_FILENAME=`basename $0`
CURRENT_DIR_PATH=$(cd `dirname $0`; pwd)

export BACKUP_DIR=${BACKUP_DIR:-"./logDiff"}
export ERROR_PATTEN=${ERROR_PATTEN:-"error|panic"}
export NAMESPACES=${NAMESPACES:-"kube-system"}


BackupLog(){

    DIR_PATH=$1

    POD_INFO=` kubectl get pod -n $NAMESPACES -o wide | sed '1d' | awk '{print $1 "  " $2 "  " $3 "  " $4}'`
    POD_NAME_LIST=` echo "$POD_INFO" | awk '{print $1 }' `

    for NAME in $POD_NAME_LIST ; do
        ( echo "storing log for pod $NAME / $NAMESPACES "   
          kubectl logs -n $NAMESPACES  $NAME &>${DIR_PATH}/${NAME} 
        )&
    done
    sleep 2
    echo ""
    echo "please wait"
    wait

    echo "$POD_INFO" >${DIR_PATH}/POD_INFO

    echo "finish store log to $1 "
}

BackupPre(){
    \rm -rf $BACKUP_DIR
    mkdir -p ${BACKUP_DIR}/old
    BackupLog ${BACKUP_DIR}/old
}

BackupAfter(){
    \rm -rf ${BACKUP_DIR}/new
    mkdir -p ${BACKUP_DIR}/new
    BackupLog ${BACKUP_DIR}/new
}

DiffLog(){
    FLAG=""
    \rm -f ${BACKUP_DIR}/report

    LIST=`ls ${BACKUP_DIR}/new` 
    for FILENAME in ${LIST} ; do
        if [ -f "${BACKUP_DIR}/old/$FILENAME" ] ; then
            ERROR_INFO=` diff ${BACKUP_DIR}/old/$FILENAME  ${BACKUP_DIR}/new/${FILENAME} | egrep -i "$ERROR_PATTEN" `
        else
            ERROR_INFO=`cat ${BACKUP_DIR}/new/${FILENAME} | egrep -i "error|panic" `
        fi
        if [ -n "$ERROR_INFO" ] ; then
            echo "#============== find error or panic from log of $NAME / $NAMESPACES , report to ${BACKUP_DIR}/report_$NAME ====================="
            echo "$ERROR_INFO" > ${BACKUP_DIR}/report_$NAME
        fi
    done

    echo ""
    NEW_POD_INFO=`cat ${BACKUP_DIR}/new/POD_INFO`
    OLD_POD_INFO=`cat ${BACKUP_DIR}/old/POD_INFO`

    HEAD_LINE="NAME         READY  STATUS  RESTARTS"

    NEW_POD_LIST=` awk '{print $1}' <<< "$NEW_POD_INFO" `
    for POD_NAME in $NEW_POD_LIST ; do
        NEW_LINE=`grep "$POD_NAME " <<< "$NEW_POD_INFO" `
        OLD_LINE=`grep "$POD_NAME " <<< "$OLD_POD_INFO" `

        if [ "$NEW_LINE" != "$OLD_LINE" ] ; then
            echo "#========== warning, find pod information change , $NAME / $NAMESPACES ( pod may happen restarting )"
            echo "                       $HEAD_LINE"
            echo "    before test <<<    $OLD_LINE"
            echo "    after test  >>>    $NEW_LINE"
            echo ""
        fi
    done

    if [ -n "$FLAG" ] ; then
        echo ""
        echo "error, please see report  "
    else
        echo "all log is ok"
    fi
}

usage(){
    echo "use this tool to diff error or panic log of pods under ${NAMESPACES} "
    echo "setup 1 : ./$CURRENT_FILENAME "
    echo "setup 2 : ..... do test.....  "
    echo "setup 3 : ./$CURRENT_FILENAME diff "
}

if   [ "$1"x == "diff"x ] ; then
    [ ! -d "$BACKUP_DIR" ] && echo "error, did not exit $BACKUP_DIR " && exit 1
    [ ! -d "${BACKUP_DIR}/old" ] && echo "error, did not exit old log " && exit 2

    BackupAfter
    DiffLog

elif [ "$1"x == "-h"x ];then
    usage
else
    BackupPre
fi

