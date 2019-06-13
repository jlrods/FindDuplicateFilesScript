#! /bin/bash

# Bash script to find duplicate files by recursively moving through the file system.
# The script may receive one argument to define the file system root, otherwise will use default root, 
# which will be the current user home directory /~.

# The script will search for not hidden files only. When running, it will record details about every file found
# in the current directory. When moved to next sub-directory, it will compare all the files in there against 
# files recorded from previous parent directory inspections.

#Declare and initialize environment variables
#Variable to use as root directory
rootDir=~
tmpDir=/tmp/FindDucplicateFiles
fInst=firstInstance.txt
dup=duplicates.txt
#Function declaration
#Function that returns the number of files in the directory passed in as parameter
countFilesInDir(){
	ls -l $1 | wc -l
}

#Funciton that returns the number of directories  in the directory passed in as parameter
countSubDirInDir(){
	ls -l $1 | grep -c ^d
}

#Function to verify a file already exists. It takes two arguments (the directory and the file name)
checkFileExists(){
	if [ -e "$1"/"$2" ]; then
		found=$((ls -l "$2" | wc -l))
	else
		touch "$1"/"$2"
		found=0
	fi
}

#Function to append a new location to an already existent file in the duplicates file.
appendNewLocation(){
	sed -i -e '/^$1/s/$/:$((pwd))' $tmpDir/$dup
}

#Function that adds an extra location to a file already present in the firstInstance file. Function first checks the 
#duplicates file exist in the temp folder. If not it creates the file and records the file data (this happens when the 
#first duplicate file is found
addInDuplicates(){
	#Check the current file is in the duplicates file
	checkFileExists "$tmpDir/$dup" "$1"
	#Check if the current file $1 is not in the duplicate file.
	if [ $found -eq 0 ]; then
		#If that is the case, the add the name to the list as this is the first time to see the file name.
		echo "$1:$((pwd))" > $tmpDir/$dup
	elif [ $found -eq 1 ]; then	
		#Append the current working directory to the end of the line where the file name is 
		appendNewLocation $1
	else
		# Include in the duplicates file name is present more than once, report an error.
		echo "Error! a file cannot be recorded more than once on $tmpDir/$dup. File name: $1"		
	fi
}

#Function that checks for the first instance of a file. Function first checks the firstInstance file exist
#in the temp folder. If not it creates the file and records the file data (this happens when the fist file
# is inspected. If firstInstance file already exists, function will look for the file name in it to determine
# what to do: add it to the firstInstance file or add the extra location of duplicate file.
checkFirstInstance(){
	#Check the current file is in the firstInstance file
	checkFileExists "$tmpDir/$fInst" "$1"
	#Check if the current file $1 is not in the firstInstance file.
	if [ $found -eq 0 ]; then
		#If that is the case, the add the name to the list as this is the first time to see the file name.
		echo "$1:$((pwd))" > $tmpDir/$fInst
	elif [ $found -eq 1 ]; then	
		# Include in the duplicates file name is present more than once, report an error.
		addDuplicates $1;
	else
		echo "Error! a file cannot be recorded more than once on $tmpDir/$fInst. File name: $1"
	fi
}

#Funtion to check all files in current directory
checkAllFiles(){
	for x in  pwd
	do
		checkFirstInstance x
	done
}

#Check the number of parameters passed in is correct. The script can accept one or no argument, other than that 
#must report an error.
if [ $# -eq 0 ] || [ $# -eq 1 ]; then
	# Assign first argument
	if [ $# -eq 1 ]; then 
		$rootDir=$1
	fi
	echo "The root directory for the current search is $rootDir"

	#Check the current root directory isn't empty
	if [ $((countFilesInDir $rootDir)) -gt 0 ] || [ $((countSubDirInDir $rooDir)) -gt 0 ]; then
		#Create a temp directory to store temporary working files
		mkdir tmpDir
		echo "Working directory has been created"
		#Start the search
		#For each file in the current directory check if its the first instance
		for d in Dir
		do 
			checkAllFiles
		do
		
	else
		#Prompt the user the root directory passed in as parameter is empty
		echo "The directory $rootDir is empty. Please, try a different location to start the search."
		exit 2
	fi
	
	
else
	#Display error message and invite user to call the script with correct number of parameters
	echo "Error. Wrong number of parameters passed in. This script can accept one or no parameters."
	echo "Please, try again."
	exit 1
fi

