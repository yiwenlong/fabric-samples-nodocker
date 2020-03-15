#!/bin/bash

function readConfValue() {
    CONF_FILE=$1
    KEY=$2
    SUB_KEY=$3
    if [ $SUB_KEY ]
    then 
        echo $(awk -F '=' '/\['$KEY'\]/{a=1}a==1&&$1~/'$SUB_KEY'/{print $2;exit}' $CONF_FILE)
    else
        echo $(awk -F '=' '/'$KEY'/{print $2;exit}' $CONF_FILE) 
    fi 
}