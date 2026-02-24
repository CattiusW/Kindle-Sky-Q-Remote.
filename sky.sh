#!/bin/sh

# Usage: ./sky.sh <IP> <COMMAND> [--legacy]
# Example: ./sky.sh 192.168.1.50 home

IP=$1
CMD_NAME=$2
PORT=49160

if [ "$3" = "--legacy" ]; then
    PORT=5900
fi

# Command Mapping (Decimal)
case "$CMD_NAME" in
    power) CODE=0 ;; select) CODE=1 ;; backup|dismiss) CODE=2 ;;
    channelup) CODE=6 ;; channeldown) CODE=7 ;; 
    home|tvguide) CODE=11 ;; i) CODE=14 ;;
    up) CODE=16 ;; down) CODE=17 ;; left) CODE=18 ;; right) CODE=19 ;;
    red) CODE=32 ;; green) CODE=33 ;; yellow) CODE=34 ;; blue) CODE=35 ;;
    sky) CODE=241 ;;
    *) echo "Unknown command: $CMD_NAME"; exit 1 ;;
esac

# Calculate Command Bytes
B7=$((224 + CODE / 16))
B8=$((CODE % 16))

# Create temp file to capture handshake
TEMP=$(mktemp)

# Send data and close connection properly
{
    # Read 12-byte handshake and echo it back
    dd bs=1 count=12 2>/dev/null | tee "$TEMP"
    
    # Send command press (Byte 2 = 1)
    printf "\x04\x01\x00\x00\x00\x00\x$(printf '%x' $B7)\x$(printf '%x' $B8)"
    
    # Send command release (Byte 2 = 0)
    printf "\x04\x00\x00\x00\x00\x00\x$(printf '%x' $B7)\x$(printf '%x' $B8)"
} | nc -w 2 $IP $PORT

rm -f "$TEMP"
