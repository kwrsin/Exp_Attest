#!/bin/sh

source ./store/web_variables.env

export ATTEST_APPID=$ATTEST_APPID
export P8_PATH=$P8_PATH
export TEAM_ID=$TEAM_ID

bundle exec ruby tests/$1