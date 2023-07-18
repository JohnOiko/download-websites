#!/bin/bash

# If the given file with the repositories's URLs is not usable, print an according error message to stderr and exit, else continue to cloning the repositories
if [ -z "$1" ]; then >&2 echo "Error: no file that contains the repositories' URLs given as first argument"
elif [ ! -e "$1" ]; then >&2 echo "Error: the file "$1" which should contain the repositories' URLs does not exist"
elif [ ! -r "$1" ]; then >&2 echo "Error: the file "$1" which should contain the repositories' URLs is not readable"
elif ! grep -q '.*\.tar\.gz$' <<< "$1"; then >&2 echo "Error: the file "$1" which should contain the repositories' URLs is not a tar.gz file"
else
	# Make a new directory if one does not already exist to save the extracted contents of the file with the repositories's URLs
	mkdir -p "repository_urls"
	# Save the path to the new directory
	repository_urls="$(pwd)/repository_urls"
	# Extract the contents of the file with the repositories's URLs to the new directory
	tar -xf $1 -C "repository_urls"

	# Make a new directory if one does not already exist to save the cloned repositories and navigate inside it
	mkdir -p "assignments"
	cd "assignments"

	# Find all the txt files in the directory with the files that contain the repositories's URLs and search them for lines that start with "https"
	# For each of the lines starting with "https" attempt to clone the repository the URL points to and if that is successful print a corresponding message to stdout and append the repository's name to an array named "repository_names", else print an error message to stderr
	declare -a repository_names=()
	while read -r line ; do
		if git clone -q "$line" &> /dev/null
		then
			echo "$line: Cloning OK"
			repository_name=$(basename $line)
			repository_name=${repository_name%.*}
			repository_names+=("$repository_name")
		else >&2 echo "$line: Cloning FAILED"; fi
	done < <(find "$repository_urls" -type f -name '*.txt' -exec grep -o -m 1 '^https[^ ]*' {} \; )

	
	# Now that the cloning of the repositories is done, the directory that was created to contain the files that have the repositories's URLs can be deleted since it is no longer needed
	rm -r "$repository_urls"

	# Iterate through each repository of the array where all the names of the successfully cloned repositories where saved
	for repository_name in "${repository_names[@]}"
	do
		# Save the number of directories, txt files and other types of files to accordingly named variables
		directory_count=$(find "$repository_name" -mindepth 1 -type d -not -path '*/.git*' | wc -l)
		text_file_count=$(find "$repository_name" -type f -name '*.txt' -and -not -path '*/.git/*' | wc -l)
		other_file_count=$(find "$repository_name" -type f ! \( -path '*/.git/*' -or -path '*.txt' \) | wc -l)
		# Print the repository's name and the number of directories, txt files and other types of files it contains
		echo "$repository_name:"
		echo "Number of directories: $directory_count"
		echo "Number of txt files: $text_file_count"
		echo "Number of other files: $other_file_count"
		# If the repository has the exact structure detailed in the exercise's instructions, print a corresponding message to stdout, else print an error message to stderr
		if [ -e "${repository_name}/dataA.txt" ] && [ -e "${repository_name}/more/dataB.txt" ] && [ -e "${repository_name}/more/dataC.txt" ] && \
		[ "$directory_count" -eq 1 ] && [ "$text_file_count" -eq 3 ] && [ "$other_file_count" -eq 0 ]
		then echo "Directory structure is OK."
		else >&2 echo "Directory structure is NOT OK."
		fi
	done
	
	# Go back to the previous directory to undo the previous directory change
	cd ..
fi
