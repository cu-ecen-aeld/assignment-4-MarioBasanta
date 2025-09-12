#!/bin/sh

# Check if exactly two arguments are passed
if [ $# -ne 2 ]; then
    echo "Error: Exactly 2 arguments required."
    echo "Usage: $0 <file_path> <string_to_write>"
    exit 1
fi

writefile=$1
writestr=$2

# Extract directory path from the full file path
writedir=$(dirname "$writefile")

# Create the directory if it doesn't exist
mkdir -p "$writedir"
if [ $? -ne 0 ]; then
    echo "Error: Could not create directory '$writedir'"
    exit 1
fi

# Write the string to the file (overwrite mode)
echo "$writestr" > "$writefile"
if [ $? -ne 0 ]; then
    echo "Error: Could not write to file '$writefile'"
    exit 1
fi

exit 0

