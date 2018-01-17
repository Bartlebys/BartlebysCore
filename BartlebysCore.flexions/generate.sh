#!/bin/sh


if [ "$#" -ne 1 ]; then
CONFIGURATION_NAME="default"
else
  CONFIGURATION_NAME=$1
fi
echo "Using $CONFIGURATION_NAME"
php -f ./generate.php "configuration=configurations/configuration.$CONFIGURATION_NAME.json"
