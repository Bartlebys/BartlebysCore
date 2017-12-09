#!/bin/sh


CONFIGURATION_NAME=$1
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <CONFIGURATION_NAME>" >&2
  exit 1
fi
echo "Using $CONFIGURATION_NAME"
php -f generate.php "configuration=configurations/configuration.$CONFIGURATION_NAME.json"