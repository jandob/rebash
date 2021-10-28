#!/usr/bin/env bash

VERSION=0.0.8

if [ -f $HOME/.rebash ]; then
  source $HOME/.rebash
else
  if [ -f /etc/.rebash ]; then
    source /etc/.rebash
  fi
fi

if [ -z "$REBASH_HOME" ]; then
  export REBASH_HOME=`dirname ${BASH_SOURCE[0]}`/src
fi

if [[ ${BASH_SOURCE[0]} != $0 ]]; then
  source $REBASH_HOME/core.sh
else
  $REBASH_HOME/doc_test.sh "${@}"
  exit $?
fi
