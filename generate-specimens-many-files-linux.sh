#!/usr/bin/env bash
#
# Script to generate ext2, ext3 and ext4 test files, that contain many files
# Requires Linux with dd and mke2fs

source ./shared_linux.sh

assert_availability_binary dd
assert_availability_binary fallocate
assert_availability_binary mke2fs
assert_availability_binary mknod
assert_availability_binary setfattr
assert_availability_binary truncate

VERSION=$( mke2fs -V 2>&1 | head -n 1 | sed 's/^mke2fs \(\S*\).*$/\1/' )

SPECIMENS_PATH="specimens/mke2fs-${VERSION}-many-files"

if test -d ${SPECIMENS_PATH}
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists."

	exit ${EXIT_FAILURE}
fi

mkdir -p ${SPECIMENS_PATH}

set -e

USERNAME=$( whoami )

MOUNT_POINT="/mnt/ext"

sudo mkdir -p ${MOUNT_POINT}

SECTOR_SIZE=512

for FILE_SYSTEM in ext2 ext3 ext4
do
	for NUMBER_OF_FILES in 100 1000 10000 100000
	do
		if test ${NUMBER_OF_FILES} -eq 100000
		then
			IMAGE_SIZE=$(( 2048 * 1024 * 1024 ))

		elif test ${NUMBER_OF_FILES} -eq 10000
		then
			IMAGE_SIZE=$(( 64 * 1024 * 1024 ))

		elif test ${NUMBER_OF_FILES} -eq 1000
		then
			IMAGE_SIZE=$(( 8 * 1024 * 1024 ))
		else
			IMAGE_SIZE=$(( 2 * 1024 * 1024 ))
		fi

		IMAGE_FILE="${SPECIMENS_PATH}/${FILE_SYSTEM}_${NUMBER_OF_FILES}_files.raw"

		echo "Creating: ${FILE_SYSTEM}; with: ${NUMBER_OF_FILES} files; with feature: dir_index; without feature: journal"
		dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null

		mke2fs -q -L "${FILE_SYSTEM}_test" -O "^has_journal,dir_index" -t ${FILE_SYSTEM} ${IMAGE_FILE}

		sudo mount -o loop,rw ${IMAGE_FILE} ${MOUNT_POINT}

		sudo chown ${USERNAME} ${MOUNT_POINT}

		create_test_file_entries ${MOUNT_POINT}

		# Create additional files
		for NUMBER in `seq 3 ${NUMBER_OF_FILES}`
		do
			if test $(( ${NUMBER} % 2 )) -eq 0
			then
				touch ${MOUNT_POINT}/testdir1/TestFile${NUMBER}
			else
				touch ${MOUNT_POINT}/testdir1/testfile${NUMBER}
			fi
		done

		sudo umount ${MOUNT_POINT}
	done
done

exit ${EXIT_SUCCESS}
