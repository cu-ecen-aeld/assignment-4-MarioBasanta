#!/bin/sh

# Check if exactly two arguments are passed
if [ $# -ne 2 ]; then
    echo "Error: Exactly 2 arguments required."
    echo "Usage: $0 <directory> <search_string>"
    exit 1
fi

filesdir=$1
searchstr=$2

# Check if the directory exists
if [ ! -d "$filesdir" ]; then
    echo "Error: Directory '$filesdir' does not exist."
    exit 1
fi

# Count number of files under filesdir (recursively)
num_files=$(find "$filesdir" -type f | wc -l)

# Count number of matching lines containing searchstr
num_matching_lines=$(grep -r "$searchstr" "$filesdir" 2>/dev/null | wc -l)

# Print result
echo "The number of files are ${num_files} and the number of matching lines are ${num_matching_lines}"

exit 0

