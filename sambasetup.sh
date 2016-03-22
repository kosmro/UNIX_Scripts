#!/bin/sh

## Version: July 2014
## Author: Robert Kosmac
##
## Description: Build Samba 4.1.11 from source and setup two shared folders and a Windows
##              compatible  Active Directory Server on Ubuntu 14.04 LTS
##              This script should work across  most Debian distros but has not been tested.
##
## Sources: https://whatandabout.files.wordpress.com/2013/05/samba-4.pdf
##          http://ubuntuforums.org/showthread.php?t=2146198
##          https://wiki.samba.org/index.php/Samba_&_Windows_Profiles#Folder_redirection
##          http://www.datastat.com/sysadminjournal/roamingsamba.html
##


echo "\n================README=======================\n"
echo "This script is written by Robert Kosmac for the purpose of making 
the setup of a Samaba Active Directory for Windows PC's much easier.
There are many different variations on how to set this system up and 
many of them are for older Ubuntu Server systems. This script has been
designed to work on the Ubuntu Server 14.04LTS system, with Samba 4.1.11.

WARNING: This script is designed to configure your Server's settings to
work as a Domain Controller. Some configuration files will be altered in
the process."


echo "\n\nDo you wish to continue? y/n"
read CONTI

case $CONTI in
      Y|y)
      
        echo "\nCommencing script...\n\n"      
        sleep 1

echo "\n================VARIABLE ENTRY=======================\n"
read -p "Please enter the desired network interface (eg wlan0): " NETCON
read -p "Enter the static IP address you want for this server: " NETADD
read -p "Enter the netmask of your network: " NETMASK
read -p "Enter the gateway address of your network: " GATEWAY
read -p "Enter the Domain Name you want for your network in capitals (eg: YOURDOMAIN.LOCAL): " DOMNMCAPS


echo "\n\n================NETWORK CONFIGURATION=======================\n"
echo "auto lo
iface lo inet loopback

auto $NETCON
iface $NETCON inet static
       address $NETADD
       netmask $NETMASK
	   gateway $GATEWAY " > /etc/network/interfaces

ifdown $NETCON
sleep 5
ifup $NETCON
sleep 10

echo "done.\n"

# This will update all currently installed packages on the server, to ensure latest updates
# Then required packages for SAMBA compiling will be installed
echo "\n\n================SETUPS AND UPDATES=======================\n"
apt-get update && apt-get upgrade -y
sleep 3
apt-get install build-essential libacl1-dev libattr1-dev libblkid-dev libgnutls-dev libreadline-dev python-dev python-dnspython gdb pkg-config libpopt-dev libldap2-dev dnsutils libbsd-dev attr krb5-user docbook-xsl libcups2-dev -y

# Download and extract official SAMBA release
echo "\n\n================DOWNLOADING SAMBA=======================\n"
wget http://www.samba.org/samba/ftp/stable/samba-4.1.11.tar.gz
sleep 5
tar xvfz samba-4.1.11.tar.gz
sleep 1

# Configure, make, make install - build and compile Samaba for your server and then install it.
echo "\n\n================COMPILE SAMBA=======================\n"
cd samba-4.1.11
./configure
sleep 5
make
sleep 5
make install



# Start SAMBA then setup the domain level and details
# Also ensures that the Administrator account has no expiry time
echo "\n\n================CONFIGURE SAMBA=======================\n"
/usr/local/samba/sbin/samba
/usr/local/samba/bin/samba-tool domain provision
sleep 5
/usr/local/samba/bin/samba-tool domain level raise  --domain-level=2008_R2
sleep 1
/usr/local/samba/bin/samba-tool domain level raise  --forest-level=2008_R2
sleep 1
/usr/local/samba/sbin/samba
echo "\nSAMBA HAS BEEN STARTED\n"
sleep 10
/usr/local/samba/bin/samba-tool user setexpiry administrator --noexpiry  


# Test the Samaba install - ensures that Windows machines will be able to contact and join the Domain
echo "\n\n================TESTING SAMBA=======================\n"
/usr/local/samba/bin/smbclient --version
sleep 5
/usr/local/samba/bin/smbclient -L localhost -U%
sleep 5
/usr/local/samba/bin/smbclient //localhost/netlogon -UAdministrator -c 'ls'
sleep 5

echo "\n\n================TESTING KERBEROS=======================\n"
kinit administrator@"$DOMNMCAPS"
sleep 3
klist
sleep 5

# Configure SAMBA share folders - this is useful for shared drives,
# Home drives, folder redirections and Roaming Profiles
echo "\n\n================SETUP SHARE FOLDERS=======================\n"
#Share for Roaming Profiles and a shared folder
mkdir -p /home/samba/userprofiles
groupadd sambausers

chmod 1777 /home/samba/userprofiles
chgrp sambausers /home/samba
chgrp sambausers /home/samba/userprofiles

echo "
[profiles]
        comment = RoamingProfiles 
        path = /home/samba/userprofiles
        read only = no
        create mask = 0600 
        directory mask = 0700
        writable = yes
        browseable = no
        guest ok = no
        printable = no
        csc policy = disable" >> /usr/local/samba/etc/smb.conf
sleep 1

#Extra Network share
mkdir -p /home/samba/ShareFolder
chmod 777 /home/samba/ShareFolder
chgrp sambausers /home/samba/ShareFolder

echo "
[Share]
        comment = Network folder 
        path = /home/samba/ShareFolder
        read only = no" >> /usr/local/samba/etc/smb.conf
sleep 1


# Adding the entry to rc.local forces SAMBA to start on boot
echo "\n\n============CONFIGURING BOOT SCRIPT============\n";

cp /etc/rc.local /etc/rc.local.old

echo "#!bin/sh -e
/usr/local/samba/sbin/samba
exit 0" > /etc/rc.local

chmod a+x /etc/rc.local

echo "\n\n================COMPLETE=======================\n"
;;
N|n)
echo "Script canceled\n"
sleep 2
;;
esac

echo "\n\n\nScript has completed. You will now need to reboot the server.\n\n"
echo "Would you like to reboot the server now? y/n"

read RECONTI

case $RECONTI in
      Y|y)
        echo "\n\n================REBOOTING IN 5 SECONDS=======================\n"
        sleep 4
        reboot
;;
    N|n)
        echo "\n\n================ENDING=======================\n"
        echo "Server will not reboot.\n\n"
        echo "Ending script..."
;;
esac
exit
