#!/bin/zsh

# Script to force computers to refresh the management framework.

# WorkFlow: Computers don't check in due to known issue PI110463, push out framework redeploy with what you gather from smart or static group

# You'll need to authorize yourself first
JSS="$(osascript -e 'Tell application "System Events" to display dialog "Please provide your Jamf Pro URL in the format, https://yourjamfinstance.jamfcloud.com" default answer "" with title "Jamf Instance" with text buttons {"Next"} default button 1' -e 'text returned of result')"
API_USER="$(osascript -e 'Tell application "System Events" to display dialog "Please log in with your Jamf Pro Admin account" default answer "" with title "API Username" with text buttons {"Next"} default button 1' -e 'text returned of result')"
API_PASS="$(osascript -e 'Tell application "System Events" to display dialog "Please enter the password for this account" default answer "" with title "API Password" with text buttons {"Next"} default button 1 with hidden answer' -e 'text returned of result')"
COMPUTER_LIST="$(osascript -e 'Tell application "System Events" to display dialog "Please provide the filepath to your computer text file" default answer "" with title "Computer List" with text buttons {"Send it!"} default button 1' -e 'text returned of result')"
response=`curl -u $API_USER:$API_PASS --basic --request POST --url $JSS/api/v1/auth/token --header 'Accept: application/json'`
token=$(echo $response | grep '"token" :' | awk -F '"' '{print $4}')

# Start yourself a handy little loop to go through each serial number in the plain text file you are 
#while read serialNumber; do
serialNumber="C02XM8A1J1GG"
    echo "Redeploying $serialNumber"

    # Now that you've authenticated, grab the id of the computer within jamf
    response=`curl --oauth2-bearer "$token" --request GET --url $JSS/JSSResource/computers/serialnumber/$serialNumber/subset/General --header 'Content-Type: application/xml'`
    echo $response

    # next, parse the id from the xml response
    ID=$(echo $response | awk -F '<' '{print $5}' | awk -F '>' '{print $2}')
    echo "Computer ID is $ID"

    # Id has been grabbed, moving on to sending the framework redeployment command
    response=`curl --oauth2-bearer "$token" --request POST --url $JSS/api/v1/jamf-management-framework/redeploy/$ID --header 'Content-Type: application/xml'`
    echo $response
#done < $COMPUTER_LIST