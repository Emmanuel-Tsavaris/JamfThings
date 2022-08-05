#!/bin/bash

# PART ONE: Find a list of Jamf Connect users who were created in the last X 
#			minutes
#
# WHY: Jamf Connect allows for just-in-time account creation on a macOS client.
# So this means that an admin may want to just pop in and do some magic, log out
# and go away.  But there's no easy way to clean up after yourself, and like any
# good Girl Scout, we should always leave our campsite better than when we found
# it.
# 
# HOW: Upload this script into Jamf Pro.  Create a policy to run the script with
# and ongoing excution frequency and set to run via Self Service.  It may make 
# sense to restrict the app to specific users and require that IT folks sign in  
# to self service to prevent some users from running the script.
#
# WHAT: We'll search all the accounts that have passwords, see if it was created
# with Jamf Connect, determine if the account was created within the last X 
# minutes (you can adjust the number below).  If yes, will be added to a space 
# delimited list of user account short names to be written to 
# /private/tmp/.userCleanup (which you can also adjust below).
# FOR SHARED COMPUTER PURPOSES: I personally will not be using this feature.

#
# Combine this with an extension attribute to read that file, a Smart Computer 
# Group to drop machines into a target group to run a policy at reoccuring 
# check-in, and a policy that reads that file and runs a jamf deleteAccount 
# command to kill that account.
#
# — SRABBITT 05JAN2022
#
# SHARED COMPUTER USECASE TAGS - ETSAVARIS 20220715

# MIT License
#
# Copyright (c) 2021 Jamf Software

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# SHARED COMPUTER USECASE: This is gonna be fun, 
# set the use of logged in user so that you can tell when they log in, and when they log out.
# put the computer in a loop to wait until the user logs in so that the script can find the users.
# then wait for the user to log out so that you can remove them.
# and finally, do it all over again from the beginning.

# Set the initial log repetition counter and current logged in user variables
loggedinuser=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}' )
logrepcount=0

# The Master Loop to ensure that the process never dies
while :
do
	# Initial Login Hook
	while :
	do
		echo "Waiting for user to log in..."
		if [[ `pgrep -x "Dock"` ]]; then
			echo "Dock lives, waiting for user to exist."
			if [[ "$loggedinuser" != "loginwindow" ]] && [[ "$loggedinuser" != "_mbsetupuser" ]] && [[ "$loggedinuser" != "root" ]]; then
				echo "Loop complete, User is logged in."
				break
			else
				sleep 5
				continue
			fi
		else
			sleep 5
			continue
		fi
	done

	# Touch file with list of users to be deleted
	DELETE_USER_TOUCH_FILE="/Library/Application Support/JAMF/Receipts/.userCleanup"
	# Credit: Steve Wood

	# Location of the Jamf binary
	JAMF_BINARY="/usr/local/bin/jamf"

	# Declare list of users variable
	listOfUsers=""

	# For all users who have a password on this machine (eliminates service accounts
	# but includes the _mbsetupuser and Jamf management accounts...)
	for user in $(/usr/bin/dscl . list /Users Password | /usr/bin/awk '$2 != "*" {print $1}'); do
		# If a user has the attribute "OIDCProvider" in their user record, they are 
		# a Jamf Connect user.
		MIGRATESTATUS=($(/usr/bin/dscl . -read /Users/$user | grep "OIDCProvider: " | /usr/bin/awk {'print $2'}))
		# If we didn't get a result, the variable is empty.  Thus that user is not 
		# a Jamf Connect Login user.
		if [[ -z $MIGRATESTATUS ]]; 
			then
				# user is not a jamf connect user
				echo "$user is Not a Jamf Connect User"
			else
				listOfUsers+=$(echo "$user ")
			fi
	done

	# If we didn't find anything, either our admin took a lot longer than 60 minutes
	# to fix the problem or something else went wrong.
	if [[ -z $listOfUsers ]];
		then
			echo "We weren't able to find any Jamf Connect Created Users."
		else
			# Otherwise, we found someone - time to tell the user that it's 
			# curtains... lacy, wafting curtains for that user.
			echo "Ladies and Gentlemen, WE GOT EM."
	fi

	# Write the list of doomed users to the doomed user file.
	echo "$listOfUsers" > "$DELETE_USER_TOUCH_FILE"

	# we'll set the script to wait until the current user is root and the Dock process is not active.
	while : 
	do
		echo "Waiting for user to log out..."
		if [[ `pgrep -x "Dock"` ]]; then
			sleep 5
			continue
		else
			echo "Dock be Dead, Waiting for the invisible man."
			if [[ "$loggedinuser" == "loginwindow" ]] || [[ "$loggedinuser" == "_mbsetupuser" ]] || [[ "$loggedinuser" == "root" ]] || [[ -z "$loggedinuser" ]]; then
				echo "Loop complete, execute order 66."
				break
			else
				echo "Still Waiting"
				continue
			fi
		fi
	done

	checkForOnlyOneAdmin=0

	# Location of the user deadpool list after running script (confirmation file 
	# for auditing)
	CONFIRM_USER_TOUCH_FILE="/private/tmp/.userDeleted"

	# Convert the space separated list of users into an array for looping through
	listOfUsers=$(cat "$DELETE_USER_TOUCH_FILE")
	arrayOfUsers=($listOfUsers)

	# If we're sanity checking for the "one admin" scenarion, look for if there
	# is only one admin with a securetoken. If true, find any standard account
	# with a securetoken and mark them for elevation.

	if [[ "$checkForOnlyOneAdmin" -eq 1 ]]; then
		adminUserCount=0
		# For all users who have a password on this machine (eliminates service accounts
		# but includes the _mbsetupuser and Jamf management accounts...)
		for user in $(/usr/bin/dscl . list /Users Password | /usr/bin/awk '$2 != "*" {print $1}'); do
			# Is the user an admin
			isUserAdmin=$(/usr/sbin/dseditgroup -m "$user" -o checkmember admin | /usr/bin/awk {'print $1'})
			if [ "$isUserAdmin" = "yes" ]; then
				# Check for securetoken status
				secureTokenStatus=$(/usr/bin/dscl . -read /Users/"$user" AuthenticationAuthority | /usr/bin/grep -o "SecureToken")
				# If the account has a SecureToken, increase the securetoken counter
				if [ "$secureTokenStatus" = "SecureToken" ]; then
					((adminUserCount++))
				fi
			fi
		done
		
		# If our admin count is less than or equal to 1 (which daymn, if we're less 
		# than one admin account on the box, we've got serious issues and shouldn't
		# even be here today...) OR if the number of users with a securetoken is 
		# equal to the size of the array of users to be deleted...
		
		echo "Admin User Count is: $adminUserCount.  Array size is: '${#arrayOfUsers[@]}'"
		
		
		if [[ "$adminUserCount" -le "1" || "$adminUserCount" -eq "${#arrayOfUsers[@]}" ]] ; then
			# Welp, we're here now, now it's time to find a standard user with
			# a securetoken so we can elevate them for a second.
			
			# For all users who have a password on this machine (eliminates service accounts
			# but includes the _mbsetupuser and Jamf management accounts...)
			for user in $(/usr/bin/dscl . list /Users Password | /usr/bin/awk '$2 != "*" {print $1}'); do
				# Is the user an admin
				isUserAdmin=$(/usr/sbin/dseditgroup -m "$user" -o checkmember admin | /usr/bin/awk {'print $1'})
				if [ "$isUserAdmin" = "no" ]; then
					# Check for securetoken status
					secureTokenStatus=$(/usr/bin/dscl . -read /Users/"$user" AuthenticationAuthority | /usr/bin/grep -o "SecureToken")
					# If the account has a SecureToken, increase the securetoken counter
					if [ "$secureTokenStatus" = "SecureToken" ]; then
						# we found an eligible canidate
						elevateThisUser="$user"
						echo "We found an eligible user: $elevateThisUser"
						# No reason to look for more users... get me out of this loop!
						break;
					fi
				fi
			done
			
			if [[ -z $elevateThisUser ]]; then
				# Error checking for no eligible users:
				echo "Something went horribly wrong and there are no eligible standard users with a SecureToken found.\
					This means we'd be deleting all the users on this machine and leave it in an unstable state.  \
					Now, theoretically this should be okay because Jamf Connect can always make new users but \
					nobody could decrypt the FileVault drive without the PRK and Apple donna like that.  Aborting."
				exit 999;
			fi
			
		else
			echo "Something went horribly wrong and there are no admin users with a SecureToken found.  We should never, ever get to this point.  Aborting."
			exit 666;
		fi
		# Elevate our eligible account.
		echo "Elevating $elevateThisUser"
		/usr/sbin/dseditgroup -o edit -a "$elevateThisUser" -t user admin
	fi

	# For every user in the list, delete the user account with the Jamf binary
	for user in ${arrayOfUsers[@]}; do
		
		echo "Deleting $user"
		############################################################################
		############################################################################
		### HERE'S WHERE YOU UNCOMMENT STUFF FOR DATA LOSS TO PURPOSELY HAPPEN!! ###
		############################################################################
		############################################################################
		# It's not that I don't trust you.  I don't trust anyone.
		# Funny thing... Locally run scripts need to be elevated to actually do this.
		echo "rm -r /Users/$user, dscl . -delete /Users/$user"
		rm -r /Users/$user
        dscl . -delete /Users/$user
	done

	# Demote our user back to standard user if needed
	if [[ -z $elevateThisUser ]]; then
		echo "We didn't have to elevate a user in this case."
	else
		echo "Demoting $elevateThisUser to standard account"
		/usr/sbin/dseditgroup -o edit -d "$elevateThisUser" -t user admin
	fi

	# Move the delete file for auditing purposes
	/bin/mv "$DELETE_USER_TOUCH_FILE" "$CONFIRM_USER_TOUCH_FILE"
	# SHARED COMPUTER USECASE:	Now that this is done, remember our Daemon writes output to .log files for both error and standard output
	# Just to be clean, we'll use a counter to make sure that logs are wiped after 5 iterations of this loop
	if [[ $logrepcount -ge 5 ]]; then
		rm -r /tmp/UserDelete_stdout.log
		rm -r /tmp/UserDelete_stderr.log
		logrepcount=0
	fi
done