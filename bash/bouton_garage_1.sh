#!/bin/sh

curl -s "http://"$DomoticzIP":"$DomoticzPort"/json.htm?type=command&param=switchlight&idx=2&switchcmd=On"


