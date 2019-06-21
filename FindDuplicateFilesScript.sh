#! /bin/bash

# Bash script to find duplicate files by recursively moving through the file system.
# The script may receive one argument to define the file system root, otherwise will use default root, 
# which will be the current user home directory(/~).

# The script will search for visible files only (not hidden). When running, it will record its current location 
# in the main  directory. When moved to next sub-directory, it will compare all the files in there against files
# recorded from previous parent directory inspections. Duplicates files (files with same basename) will be stored in a separete file, where further instances 
# of previous files will be recorded with all its subsequent locations. 

#
##############################################################################################################################################################
# 																											  												 #
#							                         Declare and initialize environment variables															 #
#																											   												 #
##############################################################################################################################################################
#Variable to use as root directory
rootDir=~
#Variable to use as temporary directory to store temp files
tmpDir=/tmp/FindDuplicateFiles
#Variable to reach the files name that will store the first instance of each file
fInst=firstInstance.txt
#Variable to reach the file name that will store the duplicate locations of files
dup=duplicates.txt

##############################################################################################################################################################
# 																											  												 #
#										                          Function declaration 						 												 #
#																											   												 #
##############################################################################################################################################################
#Function that returns the number of files in the directory passed in as parameter
countFilesInDir(){
	ls -l "$1" | grep -v -c ^[d,t]
}

#Funciton that returns the number of directories  in the directory passed in as parameter
countSubDirInDir(){
	#find "$1$" -maxdepth 0 -empty
	ls -l "$1" | grep -c ^d
}

#Function to verify a file already exists. It takes two arguments (the directory and the file name)
checkFileExists(){
	if [ -e "$1" ]; then
		#If file does exist, change found env variable and assign the number of times the file name $2 shows up on the file $1
		#This value should always return 1 as no file should be twice in either  files firstInstance nor duplicates.
		#If that is not the case the, the error will be handled on the piece of code that calls this function.
		#Iterate through the file passed in as parameter and look for the file name $2, include the colom : sign to make sure sure the full 
		#name of file is captured.If this is not done shrot names that might be substrings of larger name will be captured as duplicates.
		found=$(grep -c ^"$2:" "$1")
	else
		#In case the files doesn't exist, the file  $1 is created and the found varialble is returned as 0, as file anme $2 is not there, ovbiously.
		touch "$1"
		found=0
	fi
}

#Function to append a new location to an already existent file in the duplicates.txt file.
appendNewLocation(){
	sed -i 's|'^"$1".*'|&:'"$2"'|' "$tmpDir"/"$dup"
}

#Function that adds an extra location to a file already present in the firstInstance file. Function first checks the duplicates file exist in the temp folder.
#If not, it creates the file and records the file data (this happens when the first duplicate file is found).
#Function accepts three arguments, the file name to be searched, path to location when found first and the path where the file was found last time.
#If file is not present in the duplicates.txt file the three parameters are used, otherwise only parmeter 1 and 3 are used to append the latest directory.
addDuplicates(){
	#Check the current file is in the duplicates file
	checkFileExists "$tmpDir/$dup" "$1"
	#Check if the current file $1 is not in the duplicate file.
	if [ $found -eq 0 ]; then
		#If that is the case, the add the name to the list as this is the first time to see the file name.
		echo "$1:$2:$3" >> "$tmpDir"/"$dup"
		echo ""$1" has been added to "$dup" file. First recurrence."
	elif [ $found -eq 1 ]; then	
		#Append the current working directory to the end of the line where the file name is
		appendNewLocation "$1" "$3"
		echo ""$1" has been added to "$dup" file. New recurrence."
	else
		#If file name $1 is present more than once in the duplicates.txt file, report an error.
		echo "Error! a file cannot be recorded more than once on $tmpDir/$dup. File name: $1"
		rm -r $tmpDir 
		exit 6
	fi
}

#Function that checks for the first instance of a file. Function first checks the firstInstance.txt file exist in the temp folder.
#If not, it creates the file and records the file data (this happens when the fist file is inspected. If firstInstance.txt file already exists, function will  
#look for the file name in it to determine what to do: add it to the firstInstance.txt file or add the extra location of duplicate.txt file. Function accepts
#two arguments, the file name to be searched and the path where the file was found.
checkFirstInstance(){
	#Check the current file is in the firstInstance.txt file, first parameter is the first instace file location and the second one is the file name to search
	#in the first instace file.
	checkFileExists "$tmpDir"/"$fInst" "$1"
		#Check if the current file $1 is not in the firstInstance file.
	if [ $found -eq 0 ]; then
		#If that is the case, then add the name to the list as this is the first time to see the file name $1, followed by the path to the file: $2.
		#This data is recorded in the firstInstance.txt file.
		echo "$1:$2" >> "$tmpDir"/"$fInst"
		echo ""$1" has been added to "$fInst" file."
	elif [ $found -eq 1 ]; then	
		#If it's already present in the previous file, include it in the duplicates file by calling the addDuplicates function.
		#Extract initial location where file $1 was found. First find the line in first.txt where the file name is defined, then print only the location, which
		#is always placed after files separator ":".
		firstLocation=$(grep ^"$1" "$tmpDir"/"$fInst" | awk -F ":" ' {print $2}')
		#The addDuplicates call requires three parameters to be passed in, the file name, the first location where the files was found so it can be added to
		#the duplicates file and the current location to be appended to the line where the files is specified.
		addDuplicates "$1" "$firstLocation" "$2"
	else
		#If file name $1 is present more than once in the firstInstance.txt file, report an error.
		echo "Error! a file cannot be recorded more than once on $tmpDir/$fInst. File name: $1"
		rm -r $tmpDir 
		exit 5
	fi	
}

#Recursive function to check all files and folders in the current directory (parameter passed in to function). The functions iterate through the directory tree,
#if current item is a file, the function to check if this is the first instance of the file is called. Otherwise, if the current item is a directory, the 
#function will check if current sub-directory is empty, if it isn't, recursive call is done and current item is passed as new parameter. 
checkAllFolders(){
	#Main for loop to iterate through all items (files and folders) in the directory given as a parameter.
	for f in "$1"/*
	do
		#Firstly, check if current item is a file.
		if [ -f "$f" ]; then
			#If it is a file, extract the basename and call function to check if this is the first time the file  has been seen. Pass file name and current
			#path as parameters.
			fileName=$(basename -- "$f")
			checkFirstInstance "$fileName" "$1"
		elif [ -d "$f" ]; then
			#In case the current item is a directory, check it's not empty.
			if  [ $(countFilesInDir "$f") -eq 0 ] && [ $(countSubDirInDir "$f") -eq 0 ]; then
				#Report the folder is empty if that is the case.
				echo "Empty folder: "$f""
			else
				#If not empty, recursive call to checkAllFolders function and path new  directory as parameter.
				checkAllFolders "$f"
			fi
		else
			#In case the current item being inspected is not a file or directory, an error is displayed.
			echo "Error"
			rm -r $tmpDir 
			exit 4
		fi
	done	
}


#Function that will iterate through the duplicates.txt file line by line and split the each line into two chuncks: 
#The file name as a header, followedd by the second part, a list of directory locations where files with same basename were found. This function basically 
#extract the begining of each line and set it as header, then iterate through the line and removed the locations separeted by the ":" character and relocate
#the directory paths in subsequent lines in the format Location X: /path/. The output is saved in separete file called DuplicatesFinal.txt in the temp directory
generateFinalDuplicatesFile(){
	#Check the dupli.txt files exists
	if [ -f "$tmpDir"/"$dup" ]; then
		dupFinal="DuplicatesFinal.txt"
		awk -F ":" '{print $1 ":" } {for(i=2;i<=NF;i++) print "\tLocation " (i-1) ":" "\t"$i""}' <"$tmpDir"/"$dup" > "$tmpDir"/"$dupFinal" 		
	else
		#Display error message
		echo "Error, the "$dup" file must exist in the "$tmpDir" directory!"
		rm -r $tmpDir 
		exit 3
	fi
}

##############################################################################################################################################################
# 																											  												 #
#									                              Begining of Main script 																     #
#																											  												 #
##############################################################################################################################################################
#Check the number of parameters passed in is correct. The script can accept one or no argument, other than that 
#must report an error.
if [ $# -eq 0 ] || [ $# -eq 1 ]; then
	# Assign first argument as the root directory for the search
	if [ $# -eq 1 ]; then 
		rootDir="$1"
	fi
	echo "The root directory for the current search is $rootDir"

	#Check the current root directory isn't empty
	if [ $(countFilesInDir "$rootDir") -gt 0 ] || [ $(countSubDirInDir "$rootDir") -gt 0 ]; then
		#Create a temp directory to store temporary working files if it doesn't exist
		if [ -e "$tmpDir" ]; then
			echo "$tmpDir already exists."
		else
			mkdir "$tmpDir"
			echo "Working directory $tmpDir has been created"
		fi
		
		#Once the temp directory is created, start recursive search for duplicate files by calling recursive function to iterate through the file tree.
		#Pass the root directory as initial seed for the iterative search.
		checkAllFolders "$rootDir"
		
		#Check if script found any duplicate files by checking the duplicates files exist and is not empty
		if [ -f "$tmpDir"/"$dup" ] && [ $(awk 'END {print NR}' "$tmpDir"/"$dup") -gt 0 ]; then
			#Once the search process is done, the duplicates.txt file must be presented in better looking format.
			#The proposed solution consists of calling a function that will iterate through the file line by line and split the line into two chuncks: 
			#The file name as a header, followd by the second part, a list of directory locations where files with same basename were found.
			generateFinalDuplicatesFile
			echo "The Final Duplicates file has been generated"
			
			#Move FindDuplicateFiles file to root directory 
			mv "$tmpDir"/"$dupFinal" "$rootDir"
			echo "The "$dupFinal" files has been moved to this folder: "$rootDir" and is to be displayed on the notepad."
			#Display presentable duplicates file
			#Open the DuplicatesFinal file
			gedit "$rootDir"/"$dupFinal" &
		else
			#If no duplictes files is found, means there are no duplicates in the specified directory
			echo "No duplicate files have been found on the "$rootDir" or sub-directories!"

		fi
		#Remove temporary files
		rm -r $tmpDir 
		echo "Temporary files have been removed!"
		echo "Good bye!"
		exit 0
	else
		#Prompt the user the root directory passed in as parameter is empty
		echo "The directory "$rootDir" is empty. Please, try a different location to start the search."
		exit 2
	fi
else
	#Display error message and invite user to call the script with correct number of parameters
	echo "Error. Wrong number of parameters passed in. This script can accept one or no parameters."
	echo "Please, try again."
	exit 1
fi
