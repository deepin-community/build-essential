#!/bin/bash

set -e

if ! which lsb_release >/dev/null 2>&1; then
    echo >&2 install the lsb-release package to run this script
    exit 1
fi

if ! which grep-status >/dev/null 2>&1; then
    echo >&2 install the dctrl-tools package to run this script
    exit 1
fi

esslist=essential-packages-list
case "`lsb_release -is`" in
    Debian)
	dist='sid'
	#mirror_list=http://ftp.debian.org/debian
	mirror_list="$mirror_list http://ftp.de.debian.org/debian"
	mirror_list="$mirror_list http://ftp.debian-ports.org/debian"
	;;
    Ubuntu)
	dist=`lsb_release -cs`
	mirror_list="$mirror_list http://archive.ubuntu.com/ubuntu"
	mirror_list="$mirror_list http://ports.ubuntu.com/ubuntu-ports"
	;;
    *)
	dist='n/a';;
esac

# include only linux, kfreebsd, hurd archs
# remove discontinuted archs (e.g. arm, sh)
arches=`dpkg-architecture -L \
	| egrep '^((kfreebsd|hurd)-)?[^-]+$' \
	| egrep -v '^((kfreebsd|hurd)-)?(arm|armeb|avr32|m32r|or1k|mips|powerpcel|powerpcspe|s390|sh|sh3|sh3eb|sh4eb)$'`

for arch in $arches
do
	if [ ! -f Packages-$arch ]
	then
		for mirror in $mirror_list; do
			if wget -O Packages-$arch.xz $mirror/dists/$dist/main/binary-$arch/Packages.xz
			then
				unxz -f Packages-$arch.xz
				break
			elif wget -O Packages-$arch.bz2 $mirror/dists/$dist/main/binary-$arch/Packages.bz2
			then
				bunzip2 -f Packages-$arch.bz2
				break
			elif wget -O Packages-$arch.gz $mirror/dists/$dist/main/binary-$arch/Packages.gz
			then
				gunzip -f Packages-$arch.gz
				break
			fi
		done
		rm -f Packages-$arch.{xz,bz2,gz}
	fi
	if [ ! -f Packages-$arch ]
	then
		continue
	fi

	printf > $esslist-$arch \
		'This list was generated on %s for %s\n' \
		"`LANG=C date`" "$arch"
	echo >> $esslist-$arch \
		'It contains a list of essential packages' \
		'(which are also build-essential).'
	echo >> $esslist-$arch

	grep-status -FEssential -sPackage -ni yes Packages-$arch \
		| sort >> $esslist-$arch
done
rm -f Packages-*
