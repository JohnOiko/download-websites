#!/bin/bash

# Save the path to the file containing the URLs
urls=$1

# If the given file is not usable, print an according error message to stderr and exit, else continue to processing the URLs
if [ -z "$urls" ]; then >&2 echo "Error: no file that contains URLs given as first argument"
elif [ ! -e "$urls" ]; then >&2 echo "Error: the file $urls which should contain the URLs does not exist"
elif [ ! -r "$urls" ]; then >&2 echo "Error: the file $urls which should contain the URLs is not readable"
else
	# Make a directory to save the URL's downloaded content to named "urls_content" if it does not already exist
	mkdir -p urls_content
	# Read each line of the file containing the URLs
	while read -r line
	do
		# If the line is not a comment or empty then attempt to do download its content and update the database
		if [[ "${line::1}" != "#" && ! -z $line ]]
		then
			# If wget cannot connect to the URL print the according error message to stderr and set its currrent md5sum hash to 32 zeros to signify the connection failed
			if ! wget -q -O urls_content/site_contents.html $line
			then
				>&2 echo $line FAILED
				current_md5sum=00000000000000000000000000000000
			# Else if the connection was successful the URL's content was downloaded to a file named "site_contents.html" in the "urls_content" directory whose md5sum is calculated and saved
			else
				current_md5sum=$(md5sum urls_content/site_contents.html)
				current_md5sum=${current_md5sum:0:32}
			fi
			# Remove the downloaded "site_contents.html" file since we already saved its md5sum hash and thus it is no longer needed
			rm urls_content/site_contents.html
			# If the database file already exists and is readable then search in it for the current URL
			if [ -r database.txt ]
			then
				# Save the database's line in which the current URL was found
				found_database_line=$(grep -m 1 $line database.txt)
				# If that line is empty it means the URL was not found in the database, thus print the according message to stdout and add the URL and its md5sum hash to the last line of the database file
				if [ -z "$found_database_line" ]
				then
					if [ $current_md5sum != 00000000000000000000000000000000 ]; then echo $line INIT; fi
					echo $current_md5sum - $line >> "database.txt"
				# Else save the previous md5sum hash of the URL (which is the first 32 characters of the database's line containing the URL) and update the URL's md5sum hash in the database using the "sed" command when needed
				else
					previous_md5sum=${found_database_line:0:32}
					if [[ $previous_md5sum == 00000000000000000000000000000000 && $current_md5sum != 00000000000000000000000000000000 \
					&& $current_md5sum != 00000000000000000000000000000001 ]]
					then
						echo $line INIT
						sed -i "s|$previous_md5sum - $line|$current_md5sum - $line|" database.txt
					elif [[ $previous_md5sum == 00000000000000000000000000000001 && $current_md5sum == 00000000000000000000000000000000 ]]
					then
						:
					elif [[ $previous_md5sum == 00000000000000000000000000000001 && $current_md5sum != 00000000000000000000000000000000 \
					&& $current_md5sum != 00000000000000000000000000000001 ]]
					then
						echo $line
						sed -i "s|$previous_md5sum - $line|$current_md5sum - $line|" database.txt
					elif [[ $previous_md5sum != $current_md5sum ]]
					then
						if [[ $current_md5sum == 00000000000000000000000000000000 ]]
						then
							sed -i "s|$previous_md5sum - $line|00000000000000000000000000000001 - $line|" database.txt
						elif [[ $current_md5sum != 00000000000000000000000000000001 ]]
						then
							echo $line
							sed -i "s|$previous_md5sum - $line|$current_md5sum - $line|" database.txt
						fi
					fi
				fi
			# Else if the database file does not exist or is not readable then print the according message to stdout, create the "database.txt" file and add the URL and its md5sum hash to its last line
			else
				if [ $current_md5sum != 00000000000000000000000000000000 ]; then echo $line INIT; fi
				echo $current_md5sum - $line >> "database.txt"
			fi
		fi
	done < "$urls"
	# Once all the URLs have been checked, delete the directory "urls_content" where all the URLs' downloaded files were saved since those files are no longer needed
	rm -r urls_content
fi
