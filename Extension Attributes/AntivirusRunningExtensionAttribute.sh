#!/bin/bash

until (pgrep -x "Dock" &>/dev/null); do
sleep 5
done

if (pgrep -x "Endpoint Security for Mac" &>/dev/null) || (pgrep -x "JamfProtectAgent" &>/dev/null); then
    result="True"
else
    result="False"
fi
echo "<result>$result</result>"