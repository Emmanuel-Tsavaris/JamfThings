#!/bin/bash

# Use This for Login
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

#Use This for Logout
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