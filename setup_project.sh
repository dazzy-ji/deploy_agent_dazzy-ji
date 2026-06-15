#!/usr/bin/env bash

#Setting the global variables based on user's input
PROJECT_DIR=""
ARCHIVE_NAME=""

#Signal Trap
cleanup() {
	trap '' SIGINT
	echo "SIGINT received, interrupt detected!"

	if [ -d "$PROJECT_DIR" ]; then
		echo "Current state of '$PROJECT_DIR' is being archived -> ${ARCHIVE_NAME}"
		if tar -czf "${ARCHIVE_NAME}" "$PROJECT_DIR" 2>/dev/null; then
			echo "Archive created"
		else
			echo "Failed to create archive"
		fi
		
		echo "Incomplete directory '$PROJECT_DIR' is being deleted"
		rm -rf "$PROJECT_DIR"
		echo "Workspace cleaned"
	else
		echo "There is no current directory to be cleaned up."
	fi
	exit 130
}
trap cleanup SIGINT

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
echo "Creating directory structure for '${PROJECT_DIR}' ..."

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

#Creating the files required
echo "Generating files..."
#attendance_checker.py
cat > "$PROJECT_DIR/attendance_checker.py" << 'EOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']

        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])

            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100

            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

#assets.csv
cat > "$PROJECT_DIR/Helpers/assets.csv" << 'EOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

#config.json
DEFAULT_WARNING=75
DEFAULT_FAILURE=50
cat > "$PROJECT_DIR/Helpers/config.json" << EOF
{
    "thresholds": {
        "warning": ${DEFAULT_WARNING},
        "failure": ${DEFAULT_FAILURE}
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF

#reports.log
cat > "$PROJECT_DIR/reports/reports.log" << 'EOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
EOF

echo "Files generated"

#Dynamic configuration(using read and sed)
read -rp "Do you want to update the attendance thresholds? (y/n): " UPDATE_CHOICE

if [[ "$UPDATE_CHOICE" =~ ^[Yy]$ ]]; then
	#Setting a new warning threshold
	read -rp "Enter new warning threshold: " NEW_WARNING
	#Checking if the input is a number between 0 and 100
	while [[ -n "$NEW_WARNING" ]] && ! is_numeric "$NEW_WARNING"; do
		echo "'$NEW_WARNING' is not a number between 0 and 100"
		read -rp "Enter new warning threshold: " NEW_WARNING
	done
	if [ -z "$NEW_WARNING" ]; then
		NEW_WARNING="$DEFAULT_WARNING"
	fi
	
	#Setting a new failure threshold
	read -rp "Enter new failure threshold: " NEW_FAILURE
	#Checking if the input is a number between 0 and 100
	while [[ -n "$NEW_FAILURE" ]] && ! is_numeric "$NEW_FAILURE"; do
		echo "'$NEW_FAILURE' is not a number between 0 and 100"
		read -rp "Enter new failure threshold: " NEW_FAILURE
	done
	if [ -z "$NEW_FAILURE" ]; then
		NEW_FAILURE="$DEFAULT_FAILURE"
	fi

	#Check if the failure threshold is less than the warning threshold
	while [ "$NEW_FAILURE" -ge "$NEW_WARNING" ]; do
		echo "Warning! Failure threshold is greater than warning threshold. Enter a less failure threshold"
		read -rp "Enter new failure threshold: " NEW_FAILURE
		while [[ -n "$NEW_FAILURE" ]] && ! is_numeric "$NEW_FAILURE"; do
                	echo "'$NEW_FAILURE' is not a number between 0 and 100"
                	read -rp "Enter new failure threshold: " NEW_FAILURE
        	done
        	if [ -z "$NEW_FAILURE" ]; then
                	NEW_FAILURE="$DEFAULT_FAILURE"
        	fi
	done

	#Sed command
	echo "Applying In-place edits to config.json ..."
	sed -i "s/\"warning\": *[0-9]\+/\"warning\": ${NEW_WARNING}/" "$PROJECT_DIR/Helpers/config.json"
	sed -i "s/\"failure\": *[0-9]\+/\"failure\": ${NEW_FAILURE}/" "$PROJECT_DIR/Helpers/config.json"
	echo "Thresholds updated, warning=${NEW_WARNING}, failure=${NEW_FAILURE}"
else
	echo "Default thresholds, warning=${DEFAULT_WARNING}, failure=${DEFAULT_FAILURE}"
fi

#Health Check
#Check if python is correctly installed
echo "Health Check ..."
if python3 --version >/dev/null 2>&1; then
	echo "Python found: $(python3 --version 2>&1)"
else
	echo "Warning: Failure to run. Python3 is not installed"
fi

#Check if the directory structure is correct
DIR_STRUCTURE=true
for path in "$PROJECT_DIR/attendance_checker.py" \
		"$PROJECT_DIR/Helpers/assets.csv" \
		"$PROJECT_DIR/Helpers/config.json" \
		"$PROJECT_DIR/reports/reports.log"; do
	if [ -e "$path" ]; then
		echo "'$path' found"
	else
		echo "'$path' not found"
		DIR_STRUCTURE=false
	fi
done
if $DIR_STRUCTURE; then
	echo "Setup complete!"
else
	echo "Structure incomplete!"
	exit 1
fi

