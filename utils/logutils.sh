#!/bin/bash

INFO_COLOR=34m
ERROR_COLOR=31m
SUCCESS_COLOR=32m

function logInfo {
    TAG=$1
    MESSAGE=$2
    echo -e "\033[$INFO_COLOR$TAG\033[0m $MESSAGE"
}

function logError {
    TAG=$1
    MESSAGE=$2
    echo -e "\033[$ERROR_COLOR$TAG\033[0m $MESSAGE"
}

function logSuccess {
   TAG=$1
    MESSAGE=$2
    echo -e "\033[$SUCCESS_COLOR$TAG\033[0m $MESSAGE"
}