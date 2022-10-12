#!/bin/bash

if [ -e "/Applications/Endpoint Security for Mac.app" ] || [ -e "/Applications/JamfProtect.app" ]; then
    result="True"
else
    result="False"
fi
echo "<result>$result</result>"