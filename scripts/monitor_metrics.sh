#!/bin/bash
THRESHOLD=${1:-5}
ERROR_RATE=3

if [ "$ERROR_RATE" -gt "$THRESHOLD" ]; then
  echo "Error rate $ERROR_RATE% exceeds threshold $THRESHOLD%"
  exit 1
else
  echo "Error rate $ERROR_RATE% is within threshold"
  exit 0
fi
