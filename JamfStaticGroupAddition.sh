#!/bin/zsh

# Script to force computers to be added to a static group upon completion of an installation, for the 
# purposes of scoping configuration profiles to the computer if a smart group does not do so automatically.

# WorkFlow: Installation completes, script then runs and adds computer to Static group via its serial number

# First, Grab the serial number of the computer
serialNumber=$(system_profiler SPHardwareDataType | grep "Serial Number (system):" | awk '{ print $4 }')

# Next, use that serial number to get the id of the computer within Jamf, along with it's name and mac address information.
# You'll need to authorize yourself first...
JSS=https://plow.jamfcloud.com
API_USER=$4
API_PASS=$5
response=`curl -u $API_USER:$API_PASS --basic --request POST --url $JSS/api/v1/auth/token --header 'Accept: application/json'`
token=$(echo $response | grep '"token" :' | awk -F '"' '{print $4}')

# Just figured out that you didn't need anything more than the computer serial number to add them to the static group.
# Create your body, then send it through. know that your body needs to be in an xml format
body="
<computer_group>
  <computer_additions>
    <computer>
      <serial_number>$serialNumber</serial_number>
    </computer>
  </computer_additions>
</computer_group>
"

# Specify the group that you are going to be adding to by ID
ID="7"
response=`curl --oauth2-bearer "$token" --request PUT --url $JSS/JSSResource/computergroups/id/$ID --header 'Content-Type: application/xml' --data $body`
echo $response