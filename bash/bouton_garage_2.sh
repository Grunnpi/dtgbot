#!/bin/sh

curl -s "http://"$DomoticzIP":"$DomoticzPort"/json.htm?type=command&param=switchlight&idx=6&switchcmd=On"


