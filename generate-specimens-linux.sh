#!/bin/bash
#
# Script to generate ext2, ext3 and ext4 test files
# Requires Linux with dd and mke2fs

EXIT_SUCCESS=0;
EXIT_FAILURE=1;

# Checks the availability of a binary and exits if not available.
#
# Arguments:
#   a string containing the name of the binary
#
assert_availability_binary()
{
	local BINARY=$1;

	which ${BINARY} > /dev/null 2>&1;
	if test $? -ne ${EXIT_SUCCESS};
	then
		echo "Missing binary: ${BINARY}";
		echo "";

		exit ${EXIT_FAILURE};
	fi
}

# Creates test file entries.
#
# Arguments:
#   a string containing the mount point of the image file
#
create_test_file_entries()
{
	MOUNT_POINT=$1;

	# Create an empty file
	touch ${MOUNT_POINT}/emptyfile

	# Create a directory
	mkdir ${MOUNT_POINT}/testdir1

	# Create a file that can be stored as inline data
	echo "My file" > ${MOUNT_POINT}/testdir1/testfile1

	# Create a file that cannot be stored as inline data
	cp LICENSE ${MOUNT_POINT}/testdir1/TestFile2

	# Create a hard link to a file
	ln ${MOUNT_POINT}/testdir1/testfile1 ${MOUNT_POINT}/file_hardlink1

	# Create a symbolic link to a file
	ln -s ${MOUNT_POINT}/testdir1/testfile1 ${MOUNT_POINT}/file_symboliclink1

	# Create a hard link to a directory
	# ln: hard link not allowed for directory

	# Create a symbolic link to a directory
	ln -s ${MOUNT_POINT}/testdir1 ${MOUNT_POINT}/directory_symboliclink1

	# Create a file with an UTF-8 NFC encoded filename
	touch `printf "${MOUNT_POINT}/nfc_t\xc3\xa9stfil\xc3\xa8"`

	# Create a file with an UTF-8 NFD encoded filename
	touch `printf "${MOUNT_POINT}/nfd_te\xcc\x81stfile\xcc\x80"`

	# Create a file with an UTF-8 NFD encoded filename
	touch `printf "${MOUNT_POINT}/nfd_\xc2\xbe"`

	# Create a file with an UTF-8 NFKD encoded filename
	touch `printf "${MOUNT_POINT}/nfkd_3\xe2\x81\x844"`

	# Create a file with an extended attribute
	touch ${MOUNT_POINT}/testdir1/xattr1
	setfattr -n "user.myxattr1" -v "My 1st extended attribute" ${MOUNT_POINT}/testdir1/xattr1

	# Create a directory with an extended attribute
	mkdir ${MOUNT_POINT}/testdir1/xattr2
	setfattr -n "user.myxattr2" -v "My 2nd extended attribute" ${MOUNT_POINT}/testdir1/xattr2

	# Create a file with an initial (implict) sparse extent
	truncate -s $(( 1 * 1024 * 1024 )) ${MOUNT_POINT}/testdir1/initial_sparse1
	echo "File with an initial sparse extent" >> ${MOUNT_POINT}/testdir1/initial_sparse1

	# Create a file with a trailing (implict) sparse extent
	echo "File with a trailing sparse extent" > ${MOUNT_POINT}/testdir1/trailing_sparse1
	truncate -s $(( 1 * 1024 * 1024 )) ${MOUNT_POINT}/testdir1/trailing_sparse1

	# Create a file with an uninitialized extent
	fallocate -x -l 4096 ${MOUNT_POINT}/testdir1/uninitialized1
	echo "File with an uninitialized extent" >> ${MOUNT_POINT}/testdir1/uninitialized1

	# Create a block device file
	# Need to run mknod with sudo otherwise it errors with: Operation not permitted
	sudo mknod ${MOUNT_POINT}/testdir1/blockdev1 b 24 57

	# Create a character device file
	# Need to run mknod with sudo otherwise it errors with: Operation not permitted
	sudo mknod ${MOUNT_POINT}/testdir1/chardev1 c 13 68

	# Create a pipe (FIFO) file
	mknod ${MOUNT_POINT}/testdir1/pipe1 p
}

# Creates a test image file.
#
# Arguments:
#   a string containing the path of the image file
#   an integer containing the size of the image file
#   an integer containing the sector size
#   an array containing the arguments for mke2fs
#
create_test_image_file()
{
	IMAGE_FILE=$1;
	IMAGE_SIZE=$2;
	SECTOR_SIZE=$3;
	shift 3;
	local ARGUMENTS=("$@");

	dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

	# Notes:
	# -N #  the minimum number of inodes seems to be 16
	mke2fs -q ${ARGUMENTS[@]} ${IMAGE_FILE};
}

# Creates a test image file with file entries.
#
# Arguments:
#   a string containing the path of the image file
#   an integer containing the size of the image file
#   an integer containing the sector size
#   an array containing the arguments for mke2fs
#
create_test_image_file_with_file_entries()
{
	IMAGE_FILE=$1;
	IMAGE_SIZE=$2;
	SECTOR_SIZE=$3;
	shift 3;
	local ARGUMENTS=("$@");

	create_test_image_file ${IMAGE_FILE} ${IMAGE_SIZE} ${SECTOR_SIZE} ${ARGUMENTS[@]};

	sudo mount -o loop,rw ${IMAGE_FILE} ${MOUNT_POINT};

	sudo chown ${USERNAME} ${MOUNT_POINT};

	create_test_file_entries ${MOUNT_POINT};

	sudo umount ${MOUNT_POINT};
}

assert_availability_binary dd;
assert_availability_binary fallocate;
assert_availability_binary mke2fs;
assert_availability_binary mknod;
assert_availability_binary setfattr;
assert_availability_binary truncate;

SPECIMENS_PATH="specimens/mke2fs";

if test -d ${SPECIMENS_PATH};
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists.";

	exit ${EXIT_FAILURE};
fi

mkdir -p ${SPECIMENS_PATH};

set -e;

MOUNT_POINT="/mnt/ext";

sudo mkdir -p ${MOUNT_POINT};

IMAGE_SIZE=$(( 4096 * 1024 ));
SECTOR_SIZE=512;

# Create an ext2 file system without a journal
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext2.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext2_test" "-t ext2";

# Create an ext2 file system with a specific block size
# A block size of 8192 is only available on some architectures.
for BLOCK_SIZE in 1024 2048 4096;
do
	create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext2_block_${BLOCK_SIZE}.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-b ${BLOCK_SIZE}" "-L ext2_test" "-t ext2";
done

# Create an ext2 file system with different inode sizes
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext2_inode_128.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext2_test" "-O ^has_journal" "-t ext2" "-I 128";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext2_inode_256.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext2_test" "-O ^has_journal" "-t ext2" "-I 256";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext2_inode_512.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext2_test" "-O ^has_journal" "-t ext2" "-I 512";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext2_inode_1024.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext2_test" "-O ^has_journal" "-t ext2" "-I 1024";

# Create an ext2 file system with specific features.
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext2_without_filetype.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext2_test" "-O ^filetype,^has_journal" "-t ext2";

# Create an ext3 file system without a journal
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext3_test" "-O ^has_journal" "-t ext3";

# Create an ext3 file system with a specific block size
for BLOCK_SIZE in 1024 2048 4096;
do
	create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3_block_${BLOCK_SIZE}.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-b ${BLOCK_SIZE}" "-L ext3_test" "-O ^has_journal" "-t ext3";
done

# Create an ext3 file system with different inode sizes
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3_inode_128.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext3_test" "-O ^has_journal" "-t ext3" "-I 128";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3_inode_256.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext3_test" "-O ^has_journal" "-t ext3" "-I 256";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3_inode_512.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext3_test" "-O ^has_journal" "-t ext3" "-I 512";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3_inode_1024.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext3_test" "-O ^has_journal" "-t ext3" "-I 1024";

# Create an ext3 file system with specific features.
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3_with_dir_index.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext3_test" "-O ^has_journal,dir_index" "-t ext3";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3_with_journal.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext3_test" "-t ext3";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3_without_filetype.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext3_test" "-O ^filetype,^has_journal" "-t ext3";

# TODO: create an ext3 file system with specific journal options (-J)

# Create an ext4 file system without a journal
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal" "-t ext4";

# Create an ext4 file system with a specific block size
for BLOCK_SIZE in 1024 2048 4096;
do
	create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_block_${BLOCK_SIZE}.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-b ${BLOCK_SIZE}" "-L ext4_test" "-O ^has_journal" "-t ext4";
done

# Create an ext4 file system with different inode sizes
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_inode_128.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal" "-t ext4" "-I 128";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_inode_256.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal" "-t ext4" "-I 256";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_inode_512.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal" "-t ext4" "-I 512";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_inode_1024.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal" "-t ext4" "-I 1024";

# Create an ext4 file system with large extended attribute values
create_test_image_file "${SPECIMENS_PATH}/ext4_with_ea_inode.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,ea_inode" "-t ext4";

sudo mount -o loop,rw ${IMAGE_FILE} ${MOUNT_POINT};

sudo chown ${USERNAME} ${MOUNT_POINT};

create_test_file_entries ${MOUNT_POINT};

read -d "" -N 8192 -r LARGE_XATTR_DATA < LICENSE;
touch ${MOUNT_POINT}/testdir1/large_xattr
setfattr -n "user.mylargexattr" -v "${LARGE_XATTR_DATA}" ${MOUNT_POINT}/testdir1/large_xattr

sudo umount ${MOUNT_POINT};

# Create an ext4 file system with specific features.
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_64bit.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,64bit" "-t ext4";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_casefold.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,casefold" "-t ext4";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_dir_index.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,dir_index" "-t ext4";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_encrypt.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,encrypt" "-t ext4";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_huge_file.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,huge_file" "-t ext4";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_inline_data.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,inline_data" "-t ext4" "-I 256";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_journal.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-t ext4";
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_without_filetype.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^filetype,^has_journal" "-t ext4";

# Create an ext4 file system with block groups
#   blocks per group (-g)
#   number of groups (-G)
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_block_groups.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-G 4" "-O ^has_journal,flex_bg" "-t ext4";

# Create an ext4 file system with metadata block groups
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_metadata_block_group.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,^resize_inode,meta_bg" "-t ext4";

# TODO: create an ext4 file system with extended date and time values

# TODO: create an ext4 file system with specific journal options (-J)

# TODO: create an ext4 file system with a specific cluster size (-C)
# TODO: create an ext4 file system with a specific inode size (-i or -I)

# Create ext file systems with many files
for FILE_SYSTEM in ext2 ext3 ext4;
do
	for NUMBER_OF_FILES in 100 1000 10000 100000;
	do
		if test ${NUMBER_OF_FILES} -eq 100000;
		then
			IMAGE_SIZE=$(( 2048 * 1024 * 1024 ));

		elif test ${NUMBER_OF_FILES} -eq 10000;
		then
			IMAGE_SIZE=$(( 64 * 1024 * 1024 ));

		elif test ${NUMBER_OF_FILES} -eq 1000;
		then
			IMAGE_SIZE=$(( 8 * 1024 * 1024 ));
		else
			IMAGE_SIZE=$(( 1 * 1024 * 1024 ));
		fi

		IMAGE_NAME="${FILE_SYSTEM}_${NUMBER_OF_FILES}_files.raw"
		IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

		dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

		mke2fs -q -L "${FILE_SYSTEM}_test" -O "^has_journal,dir_index" -t ${FILE_SYSTEM} ${IMAGE_FILE};

		sudo mount -o loop,rw ${IMAGE_FILE} ${MOUNT_POINT};

		sudo chown ${USERNAME} ${MOUNT_POINT};

		create_test_file_entries ${MOUNT_POINT};

		# Create additional files
		for NUMBER in `seq 3 ${NUMBER_OF_FILES}`;
		do
			if test $(( ${NUMBER} % 2 )) -eq 0;
			then
				touch ${MOUNT_POINT}/testdir1/TestFile${NUMBER};
			else
				touch ${MOUNT_POINT}/testdir1/testfile${NUMBER};
			fi
		done

		sudo umount ${MOUNT_POINT};
	done
done

# Create ext file systems that contain large nearly sparse files
IMAGE_SIZE=$(( 1 * 1024 * 1024 ));

for FILE_SYSTEM in ext2 ext3 ext4;
do
	IMAGE_NAME="${FILE_SYSTEM}_sparse.raw"
	IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

	dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

	mke2fs -q -L "${FILE_SYSTEM}_test" -b 1024 -O "^has_journal,dir_index" -t ${FILE_SYSTEM} ${IMAGE_FILE};

	sudo mount -o loop,rw ${IMAGE_FILE} ${MOUNT_POINT};

	sudo chown ${USERNAME} ${MOUNT_POINT};

	# 256 KiB should fill up the direct blocks
	truncate -s $(( 256 * 1024 )) ${MOUNT_POINT}/sparse_256k;
	echo "sparse_256k" >> ${MOUNT_POINT}/sparse_256k;

	# 64 MiB should fill up the indirect blocks
	truncate -s $(( 64 * 1024 * 1024 )) ${MOUNT_POINT}/sparse_64m;
	echo "sparse_64m" >> ${MOUNT_POINT}/sparse_64m;

	# 16 GiB should fill up the double indirect blocks
	truncate -s $(( 16 * 1024 * 1024 * 1024 )) ${MOUNT_POINT}/sparse_16g;
	echo "sparse_16g" >> ${MOUNT_POINT}/sparse_16g;

	sudo umount ${MOUNT_POINT};
done

# Create an ext4 file system with huge file feature that contains a large nearly sparse file
IMAGE_NAME="ext4_huge_file_sparse.raw"
IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

mke2fs -q -L "ext4_test" -b 4096 -O "^has_journal,dir_index,huge_file" -t ext4 ${IMAGE_FILE};

sudo mount -o loop,rw ${IMAGE_FILE} ${MOUNT_POINT};

sudo chown ${USERNAME} ${MOUNT_POINT};

# 16 TiB is the maximum ext4 file size
truncate -s $(( ( 16 * 1024 * 1024 * 1024 * 1024 ) - ( 2 * 4096 ) )) ${MOUNT_POINT}/sparse_16t;
echo "sparse_16t" >> ${MOUNT_POINT}/sparse_16t;

sudo umount ${MOUNT_POINT};

exit ${EXIT_SUCCESS};

