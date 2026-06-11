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
