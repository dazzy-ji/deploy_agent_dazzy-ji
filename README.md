# Project: Automated Project Bootstrapping & Process Management

A shell script that builds a "Project Factory" that bootstarps the 'Student Attendance Tracker' automating the creation of the workspace, configure settings via the command line, and handles system signals gracefully.

## What the shell script does
Running the file 'setup_project.sh' does the following:

1. Directory Architecture. It creates the following directory structure:
```	
-attendance_tracker_{input from user}/
	-attendance_checker.py #Main Python file
	-Helpers/
		-assets.csv #sample of student's data
		-config.json #contains the thresholds
	-reports/
		-reports.log #the log file
```

2. Dynamic Configuration
	-The script prompts the user if they want to update the attendance thresholds which had a default warning of 75% and default failure of 50%. It then uses the sed command to perfom an "in-place" edit of the config.json file to reflect the user's values. 

3. Process Management(The Trap)
	-The script uses a Signal Trap to handle user interrupts (SIGINT/Ctrl+c). If the user cancels the script mid-execution, the script catches the signal, bundles the current state of the project directory into an archive named attendance_tracker_{input from user}_archive, and then deletes the incomplete directory to keep the workspace clean.

4. Environment Validation
	-The script perfoms a "Health Check". It verifies if python3 is installed in the local system and ensures that the application directory structure is followed.

## How to run
# 1. Make the script executable
	chmod +x setup_project.sh

# 2. Run the script
	bash setup_project.sh

## How to activate 'The Trap' signal
	1. Run the script; bash setup_project.sh
	2. Press Ctrl+C
	3. The system catches the interupt
	4. The system bundles the current state of the directory into attendance_tracker_{input}_archive
	5. The system deletes the incomplete directory
	6. SIGINT is terminated by exit status 130

## Error handling
- When you enter a directory that exists, the system refuses to create the directory and prompts you to either delete the directroy or rename.
- The system checks if the user has write permissions before allowing them to create anything.
- The workspace name entered by the user must be a whole number or the system will not allow to create the directory.
- The thersholds entered by the user must be numbers between 0 and 100, and the warning threshold must be greater than the failure threshold. 

## Requirements
- Bash
- python3

## The Link to the walkthrough video: 
	https://drive.google.com/file/d/1ocooU4CrFS5-byL9SwtxkvxZohtzt-4u/view?usp=sharing	 
