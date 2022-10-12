#!/bin/bash

if [ -e "/var/tmp/depnotify.log" ]; then
    result="True"
else
    result="False"
fi
echo "<result>$result</result>"