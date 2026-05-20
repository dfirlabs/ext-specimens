#!/usr/bin/env bash
#
# Script to generate ext2, ext3 and ext4 test files, that contain encrypted files
# Requires Linux with dd and mke2fs

source ./shared_linux.sh

assert_availability_binary dd
assert_availability_binary e4crypt
assert_availability_binary fallocate
assert_availability_binary keyctl
assert_availability_binary mke2fs
assert_availability_binary mknod
assert_availability_binary setfattr
assert_availability_binary truncate

VERSION=$( mke2fs -V 2>&1 | head -n 1 | sed 's/^mke2fs \(\S*\).*$/\1/' )

SPECIMENS_PATH="specimens/mke2fs-${VERSION}-encrypted"

if test -d ${SPECIMENS_PATH}
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists."

	exit ${EXIT_FAILURE}
fi

mkdir -p ${SPECIMENS_PATH}

set -e

USERNAME=$( whoami )

echo -n "secret_passphrase" | e4crypt add_key -S 0x1234

POLICY_IDENTIFIER=$( keyctl show @s | grep 'logon:' | tail -n 1 | sed s'/^.*logon: ext[234]://' )

if test -z "${POLICY_IDENTIFIER}"
then
	echo "Unable to determine e4crypt policy identifier"

	exit ${EXIT_FAILURE}
fi

MOUNT_POINT="/mnt/ext"

sudo mkdir -p ${MOUNT_POINT}

IMAGE_SIZE=$(( 4096 * 1024 ))
SECTOR_SIZE=512

IMAGE_FILE="${SPECIMENS_PATH}/ext4_with_encrypted_files.raw"

# Create ext file systems that contains encrypted files
echo "Creating: ext4; with feature: encrypt; without feature: journal"

create_test_image_file ${IMAGE_FILE} ${IMAGE_SIZE} ${SECTOR_SIZE} "-L ext4_test" "-O ^has_journal,encrypt" "-t ext4"

sudo mount -o loop,rw ${IMAGE_FILE} ${MOUNT_POINT}

sudo chown ${USERNAME} ${MOUNT_POINT}

create_test_file_entries ${MOUNT_POINT}

# Created an encrypted directory
mkdir ${MOUNT_POINT}/encrypteddir1
e4crypt set_policy ${POLICY_IDENTIFIER} ${MOUNT_POINT}/encrypteddir1

# Created an encrypted file
echo "Super secret" > ${MOUNT_POINT}/encrypteddir1/encryptedfile1

sudo umount ${MOUNT_POINT}

exit ${EXIT_SUCCESS}
