#!/bin/sh
if [ "$(uname)" = "Darwin" ]; then
	if [ "$(uname -p)" = "arm" ] || [ "$(uname -p)" = "arm64" ]; then
		echo "Tool LiRa1n"
		echo "by LiRa Team"
		echo "Press enter to continue"
		read -r REPLY
		ARM=yes
	fi
fi

CURRENTDIR=$(pwd)
LIRA1NDIR=$(mktemp -d)

cat << "EOF"
Copyright (C) 2020 - 2021, LiRaTeam.
EOF
read -r REPLY

if ! which curl > /dev/null; then
	echo "Error: cURL not found."
	exit 1
fi
if [ "${ARM}" != yes ]; then
	if ! which iproxy > /dev/null; then
		echo "Error: iproxy not found."
		exit 1
	fi
fi

cd "$LIRA1NDIR"

echo '#!/bin/bash' > LiRa1n-install.bash
if [ ! "${ARM}" = yes ]; then
	echo 'cd /var/root' >> LiRa1n-install.bash
fi
cat << "EOF" >> LiRa1n-install.bash
if [[ -f "/.LiRaTeam" ]]; then
    echo "Error: Migration from other bootstraps is no longer supported."
    rm ./bootstrap* ./*.deb LiRa1n-install.bash
    exit 1
fi
if [[ -f "/.LiRaTeam" ]]; then
        echo "Error: LiRa1n is already installed."
        rm ./bootstrap* ./*.deb LiRa1n-install.bash
        exit 1
fi
VER=$(/binpack/usr/bin/plutil -key ProductVersion /System/Library/CoreServices/SystemVersion.plist)
if [[ "${VER%%.*}" -ge 12 ]] && [[ "${VER%%.*}" -lt 13 ]]; then
    CFVER=12
elif [[ "${VER%%.*}" -ge 13 ]] && [[ "${VER%%.*}" -lt 14 ]]; then
    CFVER=13
elif [[ "${VER%%.*}" -ge 14 ]] && [[ "${VER%%.*}" -lt 15 ]]; then
    CFVER=14
else
    echo "${VER} not compatible."
    exit 1
fi
mount -o rw,union,update /dev/disk0s1s1
rm -rf /etc/{alternatives,apt,ssl,ssh,dpkg,profile{,.d}} /Library/dpkg /var/{cache,lib}
gzip -d bootstrap_${CFVER}.tar.gz
tar --preserve-permissions -xkf bootstrap_${CFVER}.tar -C /
SNAPSHOT=$(snappy -s | cut -d ' ' -f 3 | tr -d '\n')

snappy -f / -r "$SNAPSHOT" -t orig-fs > /dev/null 2>&1
/bootstrap.sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games
echo "Installing System.."
dpkg -r --force-remove-essential science.xnu.substituted com.ex.substitute com.saurik.substrate.safemode
dpkg -i lirasafemode_1.2_iphoneos-arm.deb > /dev/null
dpkg -i lirastuti_1.2b2_iphoneos-arm.deb > /dev/null
dpkg -i com.hoahuynh.lirastutiapp_1.0_iphoneos-arm.deb > /dev/null
dpkg -i essential_2-0_iphoneos-arm.deb > /dev/null
dpkg -i fix-firmwave_1.0_iphoneos-arm.deb > /dev/null
echo "Installing Cydia..."
dpkg -i cydia-lproj_1.1.32~b1_iphoneos-arm.deb > /dev/null
dpkg -i cydia_1.1.36_iphoneos-arm.deb > /dev/null
uicache -p /Applications/Cydia.app
mkdir -p /etc/apt/sources.list.d /etc/apt/preferences.d
{
    echo "Types: deb"
    echo "URIs: https://lirateam.github.io/apt/"
    echo "Suites: ./"
    echo "Components: "
    echo ""   
} > /etc/apt/sources.list.d/LiRa.sources
touch /var/lib/dpkg/available
touch /.mount_rw
touch /.installed_LiRa1n
apt-get update -o Acquire::AllowInsecureRepositories=true
apt-get dist-upgrade -y --allow-downgrades --allow-unauthenticated
uicache -p /var/binpack/Applications/loader.app
rm ./bootstrap* ./*.deb LiRa1n-install.bash
echo "Done!"
EOF

echo "(1) Downloading resources..."
IPROXY=$(iproxy 28605 44 >/dev/null 2>&1 & echo $!)
curl -sLOOOOO https://lirateam.github.io/LiRa1n/bootstrap_12.tar.gz \
	https://lirateam.github.io/LiRa1n/bootstrap_13.tar.gz \
	https://lirateam.github.io/LiRa1n/bootstrap_14.tar.gz \
	https://lirateam.github.io/LiRa1n/lirasafemode_1.2_iphoneos-arm.deb \
	https://lirateam.github.io/LiRa1n/lirastuti_1.2b2_iphoneos-arm.deb \
   https://lirateam.github.io/LiRa1n/com.hoahuynh.lirastutiapp_1.0_iphoneos-arm.deb \
   https://lirateam.github.io/LiRa1n/essential_2-0_iphoneos-arm.deb \
   https://lirateam.github.io/LiRa1n/fix-firmwave_1.0_iphoneos-arm.deb \
   https://lirateam.github.io/LiRa1n/cydia-lproj_1.1.32~b1_iphoneos-arm.deb \
   https://lirateam.github.io/LiRa1n/cydia_1.1.36_iphoneos-arm.deb
if [ ! "${ARM}" = yes ]; then
	echo "(2) Copying resources to your device..."
	echo "Default password is: alpine"
	scp -qP28605 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" bootstrap_12.tar.gz \
		bootstrap_13.tar.gz bootstrap_14.tar.gz \
		lirasafemode_1.2_iphoneos-arm.deb \
		lirastuti_1.2b2_iphoneos-arm.deb \
		com.hoahuynh.lirastutiapp_1.0_iphoneos-arm.deb \
		essential_2-0_iphoneos-arm.deb \
		fix-firmwave_1.0_iphoneos-arm.deb \
		cydia-lproj_1.1.32~b1_iphoneos-arm.deb \
		cydia_1.1.36_iphoneos-arm.deb\
		LiRa1n-install.bash \
		root@127.0.0.1:/var/root/
fi
echo "(3) Bootstrapping your device..."
if [ "${ARM}" = yes ]; then
	bash LiRa1n-install.bash
else
	echo "Default password is: alpine"
	ssh -qp28605 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" root@127.0.0.1 "bash /var/root/LiRa1n-install.bash"
	kill "$IPROXY"
	cd "$CURRENTDIR"
	rm -rf "$LIRA1NDIR"
fi
