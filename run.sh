#!/bin/sh

CURRENT_DIR=$(PWD)
SWIFT_PROJECT_NAME=BartlebysCore

docker run --rm\
	   --interactive\
	   --tty\
	   --volume $CURRENT_DIR:/$SWIFT_PROJECT_NAME\
	   --workdir /$SWIFT_PROJECT_NAME\
	   --name $SWIFT_PROJECT_NAME swift
