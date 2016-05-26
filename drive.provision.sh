#!/bin/sh

#===============================================#
# Auto drive provision for data drive /dev/sdc
#===============================================#

# Check root privilages
GOTROOT=`whoami`
if [ "$GOTROOT" != "root" ]; then
	echo "must be root to execute"
	exit 1
fi

# Determine the path assigned to the new drive, make a note of the logical name (e.g. /dev/sdc).
# lshw -C disk

# HDDs of exactly   1.0 TB  have: 1,953,125,000  sectors.
# Target Device: need to grep and awk to find drive >= 1TB
TGTDEV=/dev/sdc

# to create the partitions programatically (rather than manually)
# REF: http://superuser.com/questions/332252/creating-and-formating-a-partition-using-a-bash-script
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "defualt" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TGTDEV}
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
    # default, extend partition to end of disk
  w # write the partition table
  q # and we're done
EOF

# Format the drive && modify reserved space
mkfs -t ext3 ${TGTDEV}1 && tune2fs -m 0 ${TGTDEV}1
# Add the drive mount details at the end of the fstab file.
echo "\n${TGTDEV}1 \t/media/data \text3 \tdefaults \t0 \t2" >> /etc/fstab
# Create new mount point, reload fstab and mount new drive to /media/data
DATA=/media/data
if [ ! -d "$DATA" ]; then
  mkdir $DATA
fi

cd /media && mount -a

exit 1