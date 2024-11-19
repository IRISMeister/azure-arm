#!/bin/bash

if [ -f .cert-create-done ]; then
  echo "You've already executed this shell. Do again? [y/N]:"
  read ANS

  case $ANS in
    [Yy]* )
      ;;
    * )
      exit
      ;;
  esac
fi

pushd apache-ssl

p1=01
p2=01
if [ ! -z "$1" ]; then
    p1=$1
fi
if [ ! -z "$2" ]; then
    p2=$2
fi

# for external apache
./setup.sh webgateway.example.org $p1 $p2
cp ssl/* ../webgateway/build/ssl/web/

# for web browsers
./setup.sh client01 $p1 $p2
cp ssl/* ../webgateway/build/ssl/browsers/client01/

rm ext/server.cnf
popd

touch .cert-create-done