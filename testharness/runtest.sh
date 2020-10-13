#!/bin/bash

# use command line parameter for Test ID

if [ "$1" == "" ]; then
    echo "You must supply a Test Id string!!"
    exit
fi

TEST_ID=$1

# set some variable values
TEST_DATE=`date +%d%m%y`
YCSB_HOME=/home/hduser/ycsb-0.14.0
YELLOW="\033[0;33m"
NOCOLOUR="\033[0m"

OUTPUT_DIR="$YCSB_HOME/output/$TEST_ID"
mkdir $OUTPUT_DIR


# for each database / for each workload / for each op count
for db in `cat testdbs.txt`
do
    echo -e "DATABASE: $db"
    for wl in `cat workloadlist.txt` 
    do
        echo -e "\tWORKLOAD: $wl"
        for oc in `cat opcounts.txt` 
        do
            echo -e "\t\tOPCOUNT: $oc"
            echo -e "\t\t\t$Running clear down"
            if [ "$db" == "jdbc" ]; then
                echo -e "\t\t\t jdbc"
                mysql -uroot -ppassword < ./usertableClear.sql
            fi
            if [ "$db" == "mongodb" ]; then
                echo -e "\t\t\t mongodb"
                mongo < ./usertableClear.js
            fi
            if [ "$db" == "cassandra2-cql" ]; then
                echo -e "\t\t\t cassandra2-cql"
                cqlsh -f ./usertableClear.cql
            fi
            if [ "$db" == "hbase10" ]; then
                echo -e "\t\t\t hbase10"
                ./usertableClear.hbase
            fi
            for phaseType in load run 
            do
                echo -e "\t\t\tRunning $phaseType phase"
                if [ "$db" == "jdbc" ]; then
                    echo -e "\t\t\t jdbc"
                    echo -e "${YELLOW}"
                    $YCSB_HOME/bin/ycsb $phaseType $db -P $YCSB_HOME/jdbc-binding/conf/db.properties -P $YCSB_HOME/workloads/$wl -p recordcount=$oc -p operationcount=$oc -s| tee $OUTPUT_DIR/${db}_${wl}_${oc}_${phaseType}_${TEST_DATE}.txt
                    echo -e "${NOCOLOUR}"
                fi
                if [ "$db" == "mongodb" ]; then
                    echo -e "\t\t\t mongodb"
                    echo -e "${YELLOW}"
                    $YCSB_HOME/bin/ycsb $phaseType $db -s -P $YCSB_HOME/workloads/$wl -p recordcount=$oc -p operationcount=$oc | tee $OUTPUT_DIR/${db}_${wl}_${oc}_${phaseType}_${TEST_DATE}.txt
                    echo -e "${NOCOLOUR}"
                fi
                if [ "$db" == "cassandra2-cql" ]; then
                    echo -e "\t\t\t cassandra2-cql"
                    echo -e "${YELLOW}"
                    $YCSB_HOME/bin/ycsb $phaseType $db -P $YCSB_HOME/workloads/$wl -p hosts=localhost -p recordcount=$oc -p operationcount=$oc | tee $OUTPUT_DIR/${db}_${wl}_${oc}_${phaseType}_${TEST_DATE}.txt
                    echo -e "${NOCOLOUR}"
                fi
                if [ "$db" == "hbase10" ]; then
                    echo -e "\t\t\t hbase10"
                    echo -e "${YELLOW}"
                    $YCSB_HOME/bin/ycsb $phaseType $db -P $YCSB_HOME/workloads/$wl -p table=usertable -p columnfamily=family -p recordcount=$oc -p operationcount=$oc | tee $OUTPUT_DIR/${db}_${wl}_${oc}_${phaseType}_${TEST_DATE}.txt
                    echo -e "${NOCOLOUR}"
                fi
            done
        done
    done

done
