#! /bin/sh

## Version: April 2016
## Author: Robert Kosmac
##
## Description: Installs Ubuntu LTSP with some software
##
## Sources: http://www.havetheknowhow.com/Configure-the-server/Install-LTSP.html
##	    https://www.thefanclub.co.za/how-to/configure-update-auto-login-ubuntu-12-04-ltsp-fat-clients
##	    https://help.ubuntu.com/community/UbuntuLTSP/ProxyDHCP
##	    http://manpages.ubuntu.com/manpages/raring/man5/lts.conf.5.html
##	    http://ubuntuforums.org/showthread.php?t=2173749
##

echo "================README======================="
echo "This script is written for the setup of Ubuntu LTSP within
a standard network, where the router acts as a DHCP Server.
In this instance, you will need to add the required forwarders
for PXE Boot to the router.
For Cisco routers, add the following in your DHCP Pool:
	-> bootfile ltsp/<arch type>/pxelinux.0
	-> next-server <LTSP Server IP>
	eg:
	bootfile ltsp/i386/pxelinux.0
	next-server 10.0.12.23

REQUIREMENTS:
- Ubuntu Server 14.04
- Static Network addressing set for server
- SSH Server running
- 4GB RAM (Less than 4 is not recommended in production environment)
- 20GB avaliable space in Root (average image build with this script is between 7-10 GB)

NOTE: This script should be run as root.

WARNING: This script has not yet been fully tested and will
alter files in the process. Use at your own risk."


echo "============================================="

read -p "Do you wish to continue? (y/n)" CONTI
case $CONTI in
	[yY][eE][sS]|[yY]) ;;
	*)
	   echo "Script Canceled"
	   exit 1;
	;;
esac


echo "===================LTSP DETAILS==================="
read -p "Enter your LTSP Server IP address (eg 10.0.12.23): " NETADD
read -p "Enter your DHCP subnet address (eg 10.0.12.0): " NETWK
read -p "Enter your primary DNS Server address (eg 10.0.12.254): " DNSADD
# Specifies the architecture to be built for clients
read -p "Select Thin Client Architecture:
1. i386 (32-bit) - Older single-core (and early dual-core) devices, or clients running 2GB RAM or less.
2. amd64 (64-bit) - Modern multi-core devices, or when more than 4GB RAM on Client.
Option: (1-2) " AVAL

# Setup the ARCH value
case $AVAL in
        # Option 1 set 32-bit architechture
        1) ARCH="i386" ;;
	# Option 2 set 64-bit architechture
	2) ARCH="amd64" ;;
	# Default arcitecture set to 32-bit
	*) ARCH="i386" ;;
esac


# Sets the SSH port number used by LTSP - some environments change the default
read -p "Enter the Server SSH port in use (eg 22): " SSHPORT
# Sets the max RAM usable on the Client device for XORG, can prevent RAM demanding services from killing the device
read -p "Set the maximum amount of RAM (in percentage) allowed on the client-side device (eg 80): " XRAM

echo "===================SOFTWARE==================="
read -p "Select the desired Desktop Environment:
1. Ubuntu Desktop (Unity)
2. Gnome Destop
3. Lubuntu Desktop (LXDE)
4. Kubuntu Desktop (KDE)
5. Cinnamon Desktop (Gnome)
6. Budgie Desktop (EvolveOS)
7. No Desktop
Option: (1-7) " DSKOPT


# Ask about document processor and concatentae the package if requested
read -p "Do you want LibreOffice installed? (y/n)" LBOFF



case $DSKOPT in
	# Option 1 setup for Unity style desktop with LibreOffice if selected
	1) INSTALL=" ubuntu-desktop --no-install-recommends"
	   case $LBOFF in
		[yY][eE][sS]|[yY])
			INSTALL="$INSTALL libreoffice"
			;;
		*) ;;
	   esac ;;
	# Option 2 setup for Gnome 3 style desktop with LibreOffice if selected
	2) INSTALL=" xorg gnome-core gnome-system-tools gnome-app-install"
           case $LBOFF in
		[yY][eE][sS]|[yY])
			INSTALL="$INSTALL libreoffice"
			;;
		*) ;;
	   esac ;;
	# Option 3 setup for LXDE style desktop with LibreOffice if selected
	3) INSTALL=" lubuntu-desktop --no-install-recommends"
           case $LBOFF in
		[yY][eE][sS]|[yY])
                	INSTALL="$INSTALL libreoffice-gnome"
          		;;
		*) ;;
	   esac ;;
	# Option 4 setup for KDE 4 style desktop with LibreOffice if selected
	4) INSTALL=" kubuntu-desktop --no-install-recommends"
           case $LBOFF in
		[yY][eE][sS]|[yY])
			INSTALL="$INSTALL libreoffice-kde"
			;;
		*) ;;
	   esac ;;
	# Option 5 setup for Cinnamon 2.x desktop with LibreOffice if selected
	5)  #add-apt-repository -y ppa:moorkai/cinnamon
		INSTALL=" cinnamon"
           case $LBOFF in
		[yY][eE][sS]|[yY])
			INSTALL="$INSTALL libreoffice-gnome"
			;;
		*) ;;
	   esac ;;
	# Option 6 setup for Budgie desktop from Evolve OS, with LibreOffice if selected
	6)  add-apt-repository -y ppa:evolve-os/ppa
		INSTALL=" budgie-desktop"
           case $LBOFF in
		[yY][eE][sS]|[yY])
			INSTALL="$INSTALL libreoffice"
			;;
		*) ;;
	   esac ;;
	# Option 7 - no desktop environment, LibreOffice installed if selected
	7) INSTALL=""
	   case $LBOFF in
	   	[yY][eE][sS]|[yY])
			INSTALL="$INSTALL libreoffice"
			;;
		*) ;;
	   esac ;;
	# DEFAULT option - bad desktop selection, same as Option 5
	*)
	    case $LBOFF in
                [yY][eE][sS]|[yY])
                        INSTALL=" libreoffice"
                        ;;
                *) ;;
           esac ;;
esac

# Ask about the web browser
read -p "Do you want Firefox Browser (Flash Plugin included)? (y/n)" FFBRS
read -p "Do you want Chromium Browser? (y/n)" CHMBRS

# Concatenate the browser install to the INSTALL string

case $FFBRS in
   [yY][eE][sS]|[yY])
	INSTALL="$INSTALL firefox flashplugin-installer"
	;;
   *) ;;
esac

case $CHMBRS in
   [yY][eE][sS]|[yY])
        INSTALL="$INSTALL chromium-browser"
        ;;
   *) ;;
esac 


echo "Super! Now we will start the installation and build the server.
This may take between 30 minutes and 3 hours, depending on your internet
connection and the speed of your server.
During this time, you should not need to input anything, so go get yourself
a cuppa and relax while you wait.
CAUTION! The server will reboot when complete."



# Check to ensure that ready to go
echo "The INSTALL command (Testing):"
echo $INSTALL
read -p "Are you ready? (y/n)" VERIFYREADY

case $VERIFYREADY in
   [yY][eE][sS]|[yY]) ;;
   *)
	echo "Script Canceled"
        exit 1;
	;;
esac


# Start installation of LTSP
echo "Running updates.........."
apt-get update
sleep 2
apt-get upgrade -y
sleep 3
echo "Installing LTSP.........."
apt-get install ltsp-server dnsmasq tftpd-hpa -y
sleep 3

echo "Building initial LTSP Image.........."
ltsp-build-client --arch $ARCH



# Write to Config data to file
echo "Updating and creating configuration files.........."

sed -i 's/ipappend 2/ipappend 3/g' /var/lib/tftpboot/ltsp/$ARCH/pxelinux.cfg/default

#DSNmasq config file
echo '
dhcp-range=$NETWK,proxy
dhcp-option=vendor:PXEClient,6,2b
dhcp-no-override
pxe-prompt="Press F8 for boot menu", 3
pxe-service=x86PC, "Boot from network", /ltsp/i386/pxelinux
pxe-service=x86PC, "Boot from local hard disk"' > /etc/dnsmasq.d/ltsp.conf

#Restart DNSMASQ
service dnsmasq restart


# port=0
# log-dhcp
# tftp-root=/var/lib/tftpboot
# dhcp-boot=/ltsp/$ARCH/pxelinux.0
# dhcp-option=17,/opt/ltsp/$ARCH
# dhcp-option=vendor:PXEClient,6,2b
# dhcp-no-override
# # PXE menu
# #pxe-prompt="Press F8 for boot menu", 3
# # The known types are x86PC, PC98, IA64_EFI, Alpha, Arc_x86, Intel_Lean_Client, IA32_EFI, BC_EFI, Xscale_EFI and X86-64_EFI
# pxe-service=X86PC, "Boot from network", /ltsp/$ARCH/pxelinux
# pxe-service=X86PC, "Boot from local hard disk", 0
# dhcp-range=$NETADD,proxy
# " > /etc/dnsmasq.d/ltsp.conf




# LTS Config file
echo "[Default]
# Client settings
X_RAMPERC = $XRAM
SSH_OVERRIDE_PORT = $SSHPORT
X_COLOR_DEPTH = 32
X_NUMLOCK = True
# Force DNS Settings
DNS_SERVER = $DNSADD
" > /var/lib/tftpboot/ltsp/$ARCH/lts.conf


#echo "Building initial LTSP Image.........."
#ltsp-build-client --arch $ARCH &> ltsp-installer.log

sleep 5
echo "Installing software to image.........."
chroot /opt/ltsp/$ARCH apt-get install $INSTALL -y #&> ltsp-installer.log

sleep 5
echo "Rebuilding the LTSP image.........."
ltsp-update-sshkeys #&> ltsp-installer.log
sleep 1
ltsp-update-image $ARCH #&> ltsp-installer.log
sleep 1
sed -i 's/ipappend 2/ipappend 3/g' /var/lib/tftpboot/ltsp/$ARCH/pxelinux.cfg/default


#echo "Build is complete. Server will reboot in 10 seconds.........."
#sleep 10
# reboot
echo "Done!"

exit

