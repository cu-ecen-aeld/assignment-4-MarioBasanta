#!/bin/sh
# Tester script for assignment 1 and assignment 2
# Modified for assignment 3 part 1 - removed make steps

set -e
set -u

NUMFILES=10
WRITESTR=AELD_IS_FUN
WRITEDIR=/tmp/aeld-data
username=$(cat conf/username.txt)

if [ $# -lt 3 ]
then
	echo "Using default value ${WRITESTR} for string to write"
	if [ $# -lt 1 ]
	then
		echo "Using default value ${NUMFILES} for number of files to write"
	else
		NUMFILES=$1
	fi	
else
	NUMFILES=$1
	WRITESTR=$2
	WRITEDIR=/tmp/aeld-data/$3
fi

MATCHSTR="The number of files are ${NUMFILES} and the number of matching lines are ${NUMFILES}"

echo "Writing ${NUMFILES} files containing string ${WRITESTR} to ${WRITEDIR}"

rm -rf "${WRITEDIR}"

# create $WRITEDIR if not assignment1
assignment=$(cat ../conf/assignment.txt)

if [ "$assignment" != 'assignment1' ]
then
	mkdir -p "$WRITEDIR"
	if [ -d "$WRITEDIR" ]
	then
		echo "$WRITEDIR created"
	else
		exit 1
	fi
fi

# Run writer.sh for NUMFILES times
for i in $(seq 1 $NUMFILES)
do
	./writer.sh "$WRITEDIR/${username}$i.txt" "$WRITESTR"
done

# Run finder.sh
OUTPUTSTRING=$(./finder.sh "$WRITEDIR" "$WRITESTR")

# Clean up
rm -rf /tmp/aeld-data

# Check result
set +e
echo "${OUTPUTSTRING}" | grep "${MATCHSTR}"
if [ $? -eq 0 ]; then
	echo "success"
	exit 0
else
	echo "failed: expected ${MATCHSTR} in ${OUTPUTSTRING} but instead found"
	exit 1
fi

