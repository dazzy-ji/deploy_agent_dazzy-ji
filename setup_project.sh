#!/usr/bin/env bash

#Setting the global variables based on user's input
PROJECT_DIR=""
ARCHIVE_NAME=""

#Signal Trap
cleanup_on_interupt() {
	trap '' SIGINT
	echo "SIGINT received, interupt detected!"

	if [ -d "$PROJECT_DIR" ]; then
		echo "Current state of '$PROJECT_DIR' is being archived -> ${ARCHIVE_NAME}.tar.gz"
		if tar -czf "${ARCHIVE_NAME}.tar.gz" "$PROJECT_DIR" 2>/dev/null; then
			echo "Archive created"
		else
			echo "Failed to create archive"
		fi
		
		echo "Incomplete directory '$PROJECT_DIR' is being deleted"
		rm -rf "$PROJECT_DIR"
		echo "Workspace cleaned"
	else
		echo"There is no current directory to be cleaned up."
	fi
	exit 130
}
trap cleanup_on_interrupt SIGINT

#Checks if the user has entered an input and if the value entered is a whole number
is_numeric() {
	case "$1" in
		''|*[!0-9]*) return 1 ;;
	esac
	[ "$1" -ge 0 ] && [ "$1" -le 100 ]
}
#Prompt the user for their workspace number
read -rp "Enter a number for this workspace: " USER_INPUT

#Checks if the input is not empty and it is a whole number
while [[ -z "$USER_INPUT" || ! "$USER_INPUT" =~ ^[0-9]+$ ]]; do
	echo "Invalid input. Please enter a number"
	read -rp "Enter a number for this workspace: " USER_INPUT
done

PROJECT_DIR="attendance_tracker_${USER_INPUT}"
ARCHIVE_NAME="attendance_tracker_${USER_INPUT}_archive"

#Directory structure
echo "Creating directory structure for 'PROJECT_DIR' ..."

#Refuse to create an existing directory
if [ -d "$PROJECT_DIR" ]; then
	echo "ERROR: $PROJECT_DIR already exists"
	echo "Delete or rename directory"
	exit 1
fi

#Checks if the user has permissions
if [ ! -w "." ]; then
	echo " No write permissions. Failed to write"
	exit 1 
fi

#Creates the directories required
mkdir -p "$PROJECT_DIR/Helpers" "$PROJECT_DIR/reports"
echo "Directories created."
