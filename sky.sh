#!/bin/sh

# Usage: ./sky_remote.sh <IP> <COMMAND> [--legacy]
# Example: ./sky_remote.sh 192.168.1.50 home

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
# Byte 7: 224 + floor(code/16)
# Byte 8: code % 16
B7=$((224 + CODE / 16))
B8=$((CODE % 16))

# Format as hex for printf
H7=$(printf '%02x' $B7)
H8=$(printf '%02x' $B8)

# The Magic Sequence:
# 1. Wait for 12-byte handshake from Sky box
# 2. Echo those 12 bytes back
# 3. Send command (Byte 2 = 1)
# 4. Send command again (Byte 2 = 0) to complete "press"
{
    # We use a subshell to manage the timing/pipeline
    # Kindle's nc often lacks advanced flags, so we use a standard pipe
    dd bs=1 count=12 2>/dev/null | dd bs=1 count=12 2>/dev/null
    printf "\x04\x01\x00\x00\x00\x00\x$H7\x$H8"
    printf "\x04\x00\x00\x00\x00\x00\x$H7\x$H8"
} | nc $IP $PORT
