#!/bin/bash
set -e

if [[ $1 = -y ]]; then
    AUTO=yes
fi

if [ $(uname) = "Darwin" ]; then
    product=$(sw_vers -productName 2>/dev/null)
    if [ "$product" != "macOS" ] && [ "$product" != "Mac OS X" ]; then
        echo "It's recommended this script be ran on macOS/Linux with a clean iOS device running checkra1n attached unless migrating from older bootstrap."
        if [[ $AUTO != yes ]]; then
            read -p "Press enter to continue"
        fi
        ARM=yes
    fi
fi

if [[ $ARM == yes ]]; then
    VER=$(/binpack/usr/bin/plutil -key ProductVersion /System/Library/CoreServices/SystemVersion.plist)
elif [[ $AUTO == yes && ! -z $2 ]]; then
    VER=$2
fi

if [[ ! -z $VER ]]; then
    if [[ $VER = 14.* ]]; then
        CFVER=1700
    elif [[ $VER = 13.* ]]; then
        CFVER=1600
    elif [[ $VER = 12.* ]]; then
        CFVER=1500
    else
        echo "${VER} not compatible."
        exit 1
    fi
fi



if [[ $AUTO != yes ]]; then
    read -p "Press enter to continue"
fi

if ! which curl >> /dev/null; then
    echo "Error: curl not found"
    exit 1
fi
if [[ "${ARM}" != yes ]]; then
    if which iproxy >> /dev/null; then
        iproxy 42264 44 >> /dev/null 2>/dev/null &
        trap 'killall iproxy 2>/dev/null' ERR
    else
        echo "Error: iproxy not found"
        exit 1
    fi

    if [[ -z $SSHPASS ]]; then
        read -s SSHPASS -p "Enter the root password (default is “alpine”): "
        echo
    fi
    if [[ $SSHPASS = "" ]]; then
        SSHPASS=alpine
    fi
fi
rm -rf odyssey-tmp
mkdir odyssey-tmp
cd odyssey-tmp

cat > odyssey-device-deploy.sh <<EOT
#!/bin/bash
set -e

function cleanup() {
    rm -f bootstrap*.tar*
    rm -f migration
         rm -f lirasafemode_iphoneos-arm.deb
          rm -f lirastuti_iphoneos-arm.deb
           rm -f com.hoahuynh.lirastutiapp_iphoneos-arm.deb
          rm -f cydia-lproj_iphoneos-arm.deb
            rm -f cydia-lproj_iphoneos-arm.deb
            rm -f cydia_iphoneos-arm.deb
            rm -f fix-firmwave_iphoneos-arm.deb
    rm -f odyssey-device-deploy.sh
}
trap cleanup ERR

if [ \$(uname -p) = "arm" ] || [ \$(uname -p) = "arm64" ]; then
    ARM=yes
fi
if [[ ! "\${ARM}" = yes ]]; then
    cd /var/root
fi
if [[ -f "/.bootstrapped" ]]; then
    mkdir -p /odyssey && mv migration /odyssey
    chmod 0755 /odyssey/migration
    /odyssey/migration
    rm -rf /odyssey
else
    VER=\$(/binpack/usr/bin/plutil -key ProductVersion /System/Library/CoreServices/SystemVersion.plist)
    if [[ ! -z \$VER ]]; then
        if [[ \$VER = 14.* ]]; then
            CFVER=1700
        elif [[ \$VER = 13.* ]]; then
            CFVER=1600
        elif [[ \$VER = 12.* ]]; then
            CFVER=1500
        else
            echo "\${VER} not compatible."
            exit 1
        fi
    fi
    gzip -d bootstrap_\${CFVER}.tar.gz
    mount -uw -o union /dev/disk0s1s1
    rm -rf /etc/profile
    rm -rf /etc/profile.d
    rm -rf /etc/alternatives
    rm -rf /etc/apt
    rm -rf /etc/ssl
    rm -rf /etc/ssh
    rm -rf /etc/dpkg
    rm -rf /Library/dpkg
    rm -rf /var/cache
    rm -rf /var/lib
    tar --preserve-permissions -xf bootstrap_\${CFVER}.tar -C /
    SNAPSHOT=\$(snappy -s | cut -d ' ' -f 3 | tr -d '\n')
    snappy -f / -r \$SNAPSHOT -t orig-fs
fi
/prep_bootstrap.sh
mkdir -p /etc/apt/sources.list.d/
echo "Types: deb" > /etc/apt/sources.list.d/LiRa1n.sources
echo "URIs: https://lirateam.github.io/apt/" >> /etc/apt/sources.list.d/LiRa1n.sources
echo "Suites: ./" >> /etc/apt/sources.list.d/Library.sources
echo "Components: " >> /etc/apt/sources.list.d/LiRa1n.sources
echo "" >> /etc/apt/sources.list.d/LiRa1n.sources
mkdir -p /etc/apt/preferences.d/
echo "Package: *" > /etc/apt/preferences.d/odyssey
echo "Pin: release n=LiRa1n-ios" >> /etc/apt/preferences.d/LiRa1n
echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/LiRa1n
echo "" >> /etc/apt/preferences.d/LiRa1n
if [[ \$VER = 12.1* ]] || [[ \$VER = 12.0* ]]; then
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games dpkg -i org.swift.libswift_5.0-electra2_iphoneos-arm.deb
fi
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games dpkg -i lirasafemode_iphoneos-arm.deb lirastuti_iphoneos-arm.deb com.hoahuynh.lirastutiapp_iphoneos-arm.deb cydia-lproj_iphoneos-arm.deb cydia-lproj_iphoneos-arm.deb cydia_iphoneos-arm.deb fix-firmwave_iphoneos-arm.deb
uicache -p /Applications/Cydia.app
echo -n "" > /var/lib/dpkg/available
touch /.mount_rw
touch /.installed_LiRa1n
cleanup
EOT

echo "Downloading Resources..."
curl -#L \
    -O https://github.com/coolstar/odyssey-bootstrap/raw/master/migration \
    -O https://lirateam.github.io/LiRa1n/fix-firmwave_iphoneos-arm.deb \
    -O https://lirateam.github.io/LiRa1n/essential_iphoneos-arm.deb \
    -O https://lirateam.github.io/LiRa1n/cydia-lproj_iphoneos-arm.deb \
    -O https://lirateam.github.io/LiRa1n/cydia_iphoneos-arm.deb \
    -O https://lirateam.github.io/LiRa1n/lirasafemode_iphoneos-arm.deb \
    -O https://lirateam.github.io/LiRa1n/lirastuti_iphoneos-arm.deb \
    -O https://lirateam.github.io/LiRa1n/com.hoahuynh.lirastutiapp_iphoneos-arm.deb

if [[ ! -z $CFVER ]]; then
    curl -#L \
        -O https://lirateam.github.io/LiRa1n/bootstrap_${CFVER}.tar.gz

    if [[ $VER = 12.1* ]] || [[ $VER = 12.0* ]]; then
        curl -#L \
            -O https://github.com/coolstar/odyssey-bootstrap/raw/master/org.swift.libswift_5.0-electra2_iphoneos-arm.deb
    fi
else
    curl -#L \
        -O https://lirateam.github.io/LiRa1n/bootstrap_1500.tar.gz \
        -O https://lirateam.github.io/LiRa1n/bootstrap_1600.tar.gz \
        -O https://lirateam.github.io/LiRa1n/bootstrap_1700.tar.gz \
       
fi

if [[ ! "${ARM}" = yes ]]; then
    echo "Copying Files to your device"
    sshpass -e scp -P42264 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" \
        bootstrap_*.tar.gz \
        migration \
        lirasafemode_iphoneos-arm.deb \
         lirastuti_iphoneos-arm.deb \
         com.hoahuynh.lirastutiapp_iphoneos-arm.deb \
         cydia-lproj_iphoneos-arm.deb \
         cydia-lproj_iphoneos-arm.deb \
         cydia_iphoneos-arm.deb \
         fix-firmwave_iphoneos-arm.deb \
        odyssey-device-deploy.sh \
        root@127.0.0.1:/var/root/

    if [[ -f org.swift.libswift_5.0-electra2_iphoneos-arm.deb ]]; then
        sshpass -e scp -P42264 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" \
            org.swift.libswift_5.0-electra2_iphoneos-arm.deb \
            root@127.0.0.1:/var/root/
    fi
fi
echo "Installing Procursus bootstrap and Sileo on your device"
if [[ "${ARM}" = yes ]]; then
    bash ./odyssey-device-deploy.sh
else
    sshpass -e ssh -p42264 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" root@127.0.0.1 "bash /var/root/odyssey-device-deploy.sh"
    echo "All Done!"
    killall iproxy
fi
