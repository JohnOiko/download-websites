#!/bin/bash

# If the first argument is "-h" or "--help" then print the help message and exit
if [ "$1" == "-h" ] || [ "$1" == "--help" ]
then
	printf "Usage:\n  ./script3.sh [OPTION]\n  ./script3.sh path_to_file number\n\n"
	printf "First syntax prints this help message.\nSecond syntax prints the number most used words in the file.\n"
	printf "\nIn the second syntax, \"path_to_file\" is the path to the file which contains the Gutenberg book in text form. This file must exist and be readable.\nThe second argument \"number\" is the number of most used words in the given text file which will be printed. This number must be greater than 0.\n"
	printf "\nOptions:\n  -h, --help  print this help message.\n"
	exit 0
fi

# Save the path of the file with the project Gutenberg book and the amount of words' counts to be printed to two variables 
text_file=$1
words_shown=$2

# If the given file is not usable or the amount of words' counts to be printed is not given correctly, print an according error message to stderr and exit, else continue to processing the file with the project Gutenberg book
if [ ! -e "$text_file" ]; then >&2 echo "Error: the file $text_file does not exist"
elif [ ! -r "$text_file" ]; then >&2 echo "Error: the file $urls is not readable"
elif [ -z "$words_shown" ]; then >&2 echo "Error: no amount of words to be printed given as second argument"
elif [ $words_shown -lt 1 ]; then >&2 echo "Error: the number of most used words to be printed given as second argument must be > 0"
else
	# Initialize an associative array and two boolean variables used to know if we are passed the start and end lines 
	declare -A word_counter
	past_start_line=false
	past_end_line=false
	# Read each line of the project Gutenberg book and process it
	while read -r line
	do
		# If the current line is the start or end line set the corresponding boolean variable to true
		if [[ "$line" =~ ^\*\*\*\ START\ OF\ THIS\ PROJECT\ GUTENBERG\ EBOOK\ [^\*]*\*\*\*$ ]]; then past_start_line=true
		elif [[ "$line" =~ ^\*\*\*\ END\ OF\ THIS\ PROJECT\ GUTENBERG\ EBOOK\ [^\*]*\*\*\*$ ]]; then past_end_line=true
		# Else if the line is not empty and it is between the start and end lines adjust the counts of its words 
		elif [ ! -z "$line" ] && [ $past_start_line == true ] && [ $past_end_line == false ] 
		then
			# Split the line using a space as delimiter and save the complex words in an array named "complex_word_array"
			IFS=" " read -ra complex_word_array <<< "$line"
			# Process each complex word (including words that contain multiple words split by dashes)
			for complex_word in "${complex_word_array[@]}"
			do
				# Split each complex word using dashes as delimiter and save the new words in an array named "word_array"
				IFS="-" read -ra word_array <<< "$complex_word"
				# Process each word in the array mentioned above to bring it to the form the exercise's instructions require
				for word in "${word_array[@]}"
				do
					# Make lowercase
					word=${word,,}
					# Remove all punctuation except for "'"
					word=${word//[^a-z\']/}
					# Remove all '[letter] patterns that have at least one character before them and no characters after them
					if [[ ${#word} -gt 2 && ${word:${#word}-2} =~ \'[a-z] ]]; then word=${word//\'[a-z]/}; fi
					# Remove the remaining "'" characters
					word=${word//[\']/}
					# If the word has at least one character left after being processed and it does not already have a value in the associative array, initialize its value/count to 1
					if [ ${#word} -gt 0 ] && [ -z ${word_counter[${word}]} ]; then word_counter[$word]=1
					# Else if the word has at least one character left after being processed and it already has a value in the associative array, increment its value/count by 1
					elif [ ${#word} -gt 0 ] && [ ! -z ${word_counter[${word}]} ]; then ((word_counter[$word]++)); fi
				done <<< "$complex_word"
			done <<< "$line"
		fi
	done < "$text_file"
	# Sort the words based on their counts and print only the "words_shown" number of most used words
	for key in "${!word_counter[@]}"; do echo "$key ${word_counter[$key]}"; done | sort -nrk 2 | head -n $words_shown
fi
