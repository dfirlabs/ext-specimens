#!/usr/bin/env bash
#
# Script to generate ext2, ext3 and ext4 test files
# Requires Linux with dd and mke2fs

source ./shared_linux.sh

assert_availability_binary dd
assert_availability_binary fallocate
assert_availability_binary mke2fs
assert_availability_binary mknod
assert_availability_binary setfattr
assert_availability_binary truncate

VERSION=$( mke2fs -V 2>&1 | head -n 1 | sed 's/^mke2fs \(\S*\).*$/\1/' )

SPECIMENS_PATH="specimens/mke2fs-${VERSION}"

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

IMAGE_SIZE=$(( 4096 * 1024 ))
SECTOR_SIZE=512

# ext2

echo "Creating: ext2; without feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext2.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext2_test" "-O ^has_journal" "-t ext2"

# A block size of 8192 is only available on some architectures.
for BLOCK_SIZE in 1024 2048 4096
do
	echo "Creating: ext2; with block size: ${BLOCK_SIZE}; without feature: journal"
	create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext2_block_${BLOCK_SIZE}.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-b ${BLOCK_SIZE}" "-L ext2_test" "-O ^has_journal" "-t ext2"
done

for INODE_SIZE in 128 256 512 1024
do
	echo "Creating: ext2; with inode size: ${INODE_SIZE}; without feature: journal"
	create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext2_inode_${INODE_SIZE}.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext2_test" "-O ^has_journal" "-t ext2" "-I ${INODE_SIZE}"
done

echo "Creating: ext2; without feature: filetype, journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext2_without_filetype.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext2_test" "-O ^filetype,^has_journal" "-t ext2"

# ext3

echo "Creating: ext3; without feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext3_test" "-O ^has_journal" "-t ext3"

for BLOCK_SIZE in 1024 2048 4096
do
	echo "Creating: ext3; with block size: ${BLOCK_SIZE}; without feature: journal"
	create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3_block_${BLOCK_SIZE}.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-b ${BLOCK_SIZE}" "-L ext3_test" "-O ^has_journal" "-t ext3"
done

for INODE_SIZE in 128 256 512 1024
do
	echo "Creating: ext3; with inode size: ${INODE_SIZE}; without feature: journal"
	create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3_inode_${INODE_SIZE}.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext3_test" "-O ^has_journal" "-t ext3" "-I ${INODE_SIZE}"
done

echo "Creating: ext3; with feature: dir_index; without feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3_with_dir_index.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext3_test" "-O ^has_journal,dir_index" "-t ext3"

echo "Creating: ext3; with feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3_with_journal.raw" $(( 8192 * 1024 )) ${SECTOR_SIZE} "-L ext3_test" "-t ext3"

echo "Creating: ext3; without feature: filetype, journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext3_without_filetype.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext3_test" "-O ^filetype,^has_journal" "-t ext3"

# TODO: create an ext3 file system with specific journal options (-J)

# ext4

echo "Creating: ext4; without feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal" "-t ext4"

for BLOCK_SIZE in 1024 2048 4096
do
	echo "Creating: ext4; with block size: ${BLOCK_SIZE}; without feature: journal"
	create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_block_${BLOCK_SIZE}.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-b ${BLOCK_SIZE}" "-L ext4_test" "-O ^has_journal" "-t ext4"
done

for INODE_SIZE in 128 256 512 1024
do
	echo "Creating: ext4; with inode size: ${INODE_SIZE}; without feature: journal"
	create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_inode_${INODE_SIZE}.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal" "-t ext4" "-I ${INODE_SIZE}"
done

echo "Creating: ext4; with feature: ea_inode; without feature: journal"
create_test_image_file "${SPECIMENS_PATH}/ext4_with_ea_inode.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,ea_inode" "-t ext4"

sudo mount -o loop,rw ${IMAGE_FILE} ${MOUNT_POINT}

sudo chown ${USERNAME} ${MOUNT_POINT}

create_test_file_entries ${MOUNT_POINT}

read -d "" -N 8192 -r LARGE_XATTR_DATA < LICENSE
touch ${MOUNT_POINT}/testdir1/large_xattr
setfattr -n "user.mylargexattr" -v "${LARGE_XATTR_DATA}" ${MOUNT_POINT}/testdir1/large_xattr

sudo umount ${MOUNT_POINT}

echo "Creating: ext4; with feature: 64bit; without feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_64bit.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,64bit" "-t ext4"

echo "Creating: ext4; with feature: casefold; without feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_casefold.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,casefold" "-t ext4"

echo "Creating: ext4; with feature: dir_index; without feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_dir_index.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,dir_index" "-t ext4"

echo "Creating: ext4; with feature: encrypt; without feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_encrypt.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,encrypt" "-t ext4"

echo "Creating: ext4; with feature: huge_file; without feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_huge_file.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,huge_file" "-t ext4"

echo "Creating: ext4; with feature: inline_data; without feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_inline_data.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,inline_data" "-t ext4" "-I 256"

echo "Creating: ext4; with feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_journal.raw" $(( 8192 * 1024 )) ${SECTOR_SIZE} "-L ext4_test" "-t ext4"

echo "Creating: ext4; without feature: filetype, journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_without_filetype.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^filetype,^has_journal" "-t ext4"

echo "Creating: ext4; with feature: metadata_csum; without feature: journal, 64bit"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_metadata_csum.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,metadata_csum,^64bit" "-t ext4"

echo "Creating: ext4; with feature: metadata_csum, 64bit; without feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_metadata_csum_64bit.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,metadata_csum,64bit" "-t ext4"

# Create an ext4 file system with flex block groups
#   number of groups (-G)

echo "Creating: ext4; with feature: flex_bg; without feature: journal"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_flex_block_groups.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-G 4" "-O ^has_journal,flex_bg" "-t ext4"

# Create an ext4 file system with metadata block groups
#   blocks per group (-g)
META_BG_IMAGE_SIZE=$(( 64 * 1024 * 1024 ))

export MKE2FS_FIRST_META_BG=1

echo "Creating: ext4; with feature: meta_bg; without feature: journal, resize_inode"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_meta_block_group.raw" ${META_BG_IMAGE_SIZE} ${SECTOR_SIZE} "-b 1024" "-g 1024" "-L ext4_test" "-O ^has_journal,^resize_inode,meta_bg" "-t ext4"

export MKE2FS_FIRST_META_BG=

# TODO: create an ext4 file system with extended date and time values

# TODO: create an ext4 file system with specific journal options (-J)

# TODO: create an ext4 file system with a specific cluster size (-C)
# TODO: create an ext4 file system with a specific inode size (-i or -I)

# Note that orphan_file_size should be less than 1024
ORPHAN_FILE_SIZE=123

echo "Creating: ext4; with: orphan file size: ${ORPHAN_FILE_SIZE}; without feature: journal, resize_inode"
create_test_image_file_with_file_entries "${SPECIMENS_PATH}/ext4_with_orphan_file_size.raw" ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-E orphan_file_size=${ORPHAN_FILE_SIZE}" "-O ^has_journal" "-t ext4"

# Create ext file systems that contains large nearly sparse files
IMAGE_SIZE=$(( 1 * 1024 * 1024 ))

for FILE_SYSTEM in ext2 ext3 ext4
do
	IMAGE_NAME="${FILE_SYSTEM}_sparse.raw"
	IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}"

	echo "Creating: ${FILE_SYSTEM}; with: sparse files; with feature: dir_index; without feature: journal"

	dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null

	mke2fs -q -L "${FILE_SYSTEM}_test" -b 1024 -O "^has_journal,dir_index" -t ${FILE_SYSTEM} ${IMAGE_FILE}

	sudo mount -o loop,rw ${IMAGE_FILE} ${MOUNT_POINT}

	sudo chown ${USERNAME} ${MOUNT_POINT}

	# 256 KiB should fill up the direct blocks
	truncate -s $(( 256 * 1024 )) ${MOUNT_POINT}/sparse_256k
	echo "sparse_256k" >> ${MOUNT_POINT}/sparse_256k

	# 64 MiB should fill up the indirect blocks
	truncate -s $(( 64 * 1024 * 1024 )) ${MOUNT_POINT}/sparse_64m
	echo "sparse_64m" >> ${MOUNT_POINT}/sparse_64m

	# 16 GiB should fill up the double indirect blocks
	truncate -s $(( 16 * 1024 * 1024 * 1024 )) ${MOUNT_POINT}/sparse_16g
	echo "sparse_16g" >> ${MOUNT_POINT}/sparse_16g

	sudo umount ${MOUNT_POINT}
done

# Create an ext4 file system with huge file feature that contains a large nearly sparse file
IMAGE_NAME="ext4_huge_file_sparse.raw"
IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}"

echo "Creating: ext4; with: huge file; with feature: dir_index, huge_file; without feature: journal"

dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null

mke2fs -q -L "ext4_test" -b 4096 -O "^has_journal,dir_index,huge_file" -t ext4 ${IMAGE_FILE}

sudo mount -o loop,rw ${IMAGE_FILE} ${MOUNT_POINT}

sudo chown ${USERNAME} ${MOUNT_POINT}

# 16 TiB is the maximum ext4 file size
truncate -s $(( ( 16 * 1024 * 1024 * 1024 * 1024 ) - ( 2 * 4096 ) )) ${MOUNT_POINT}/sparse_16t
echo "sparse_16t" >> ${MOUNT_POINT}/sparse_16t

sudo umount ${MOUNT_POINT}

# TODO: create an ext4 file system where the order of logical block numbers of the extents of testdir1/TestFile2 is reversed

exit ${EXIT_SUCCESS}
