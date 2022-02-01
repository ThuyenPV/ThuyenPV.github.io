#!/usr/bin/env bash

function ping() {
  echo $1
}
function start() {
  jekyll serve
}

case $1 in
ping)
  ping "${@:2}"
  ;;
start)
  start
  ;;
*)
  echo "./test.sh [ping|start]"
  ;;
esac