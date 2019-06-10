#!/bin/sh

curl -s "http://"$DomoticzIP":"$DomoticzPort"/json.htm?type=command&param=switchlight&idx=38&switchcmd=Set%20Level&level=20"


