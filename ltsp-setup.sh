#! /bin/sh

## Version: March 2016
## Author: Robert Kosmac
##
## Description: Installs Ubuntu LTSP with some software
##
## Sources: http://www.havetheknowhow.com/Configure-the-server/Install-LTSP.html
##	    	https://www.thefanclub.co.za/how-to/configure-update-auto-login-ubuntu-12-04-ltsp-fat-clients
##	    	https://help.ubuntu.com/community/UbuntuLTSP/ProxyDHCP
##	    	http://manpages.ubuntu.com/manpages/raring/man5/lts.conf.5.html
##

echo "\n================README=======================\n"
echo "This script is written for the setup of Ubuntu LTSP within
a standard network, where the router acts as a DHCP Server.\n
In this instance, you will need to add the required forwarders
for PXE Boot to the router.\n\n
For Cisco routers, add the following in your DHCP Pool:\n
	-> bootfile ltsp/<arch type>/pxelinux.0\n
	-> next-server <LTSP Server IP>\n
	eg:\n
	bootfile ltsp/i386/pxelinux.0\n
	next-server 10.0.12.23\n
\n\n
REQUIREMENTS:\n
- Ubuntu Server 14.04
- Static Network addressing set for server
- SSH Server running
- 4GB RAM (Less than 4 is not recommended in production environment)
- 20GB avaliable space in Root (average image build with this script is between 7-10 GB)
\n
NOTE: This script should be run as root.\n\n
WARNING: This script has not yet been fully tested and will
alter files in the process. Use at your own risk."


echo "\n=============================================\n"

read -p "\n\nDo you wish to continue? (y/n)" CONTI
if [ "$CONTI" == "n" ] || [ "$CONTI" == "N" ]; then
        echo "Script Canceled"
	exit 1;
fi



# Initialize the items to install string
$INSTALL = ""

echo "\n===================LTSP DETAILS===================\n"
read -p "Enter your LTSP Server IP address (eg 10.0.12.23): " NETADD
read -p "Enter your primary DNS Server address (eg 10.0.12.254): " DNSADD
# Specifies the architecture to be built for clients
read -p "Select Thin Client Architecture:\n
1. i386 (32-bit) - Older single-core (and early dual-core) devices, or clients running 2GB RAM or less.\n
2. amd64 (64-bit) - Modern multi-core devices, or when more than 4GB RAM on Client.\n
Option: (1-2) " AVAL

# Setup the ARCH value
case $AVAL in
        # Option 1 set 32-bit architechture
        1) $ARCH = "i386" ;;
	# Option 2 set 64-bit architechture
	2) $ARCH = "amd64" ;;
	# Default arcitecture set to 32-bit
	*) $ARCH = "i386" ;;
esac


# Sets the SSH port number used by LTSP - some environments change the default
read -p "Enter the Server SSH port in use (eg 22): " SSHPORT
# Sets the max RAM usable on the Client device for XORG, can prevent RAM demanding services from killing the device
read -p "Set the maximum amount of RAM (in percentage) allowed on the client-side device (eg 80): " XRAM

echo "\n===================SOFTWARE===================\n"
read -p "Select the desired Desktop Environment:\n
1. Ubuntu Desktop (Unity)\n
2. Gnome Destop\n
3. Lubuntu Desktop (LXDE)\n
4. Kubuntu Desktop (KDE)\n
5. No Desktop\n
Option: (1-5) " DSKOPT


# Ask about document processor and concatentae the package if requested
read -p "Do you want LibreOffice installed? (y/n)" LBOFF



case $DSKOPT in
	# Option 1 setup for Unity style desktop with LibreOffice if selected
	1) $INSTALL = " ubuntu-desktop --no-install-recommends"
	   if [ "$LBOFF" == "y" ] || [ "$LBOFF" == "Y" ]; then
        	$INSTALL = "$INSTALL libreoffice"
	   fi ;;
	# Option 2 setup for Gnome 3 style desktop with LibreOffice if selected
	2) $INSTALL = " xorg gnome-core gnome-system-tools gnome-app-install"
           if [ "$LBOFF" == "y" ] || [ "$LBOFF" == "Y" ]; then
                $INSTALL = "$INSTALL libreoffice"
           fi ;;
	# Option 3 setup for LXDE style desktop with LibreOffice if selected
	3) $INSTALL = " lubuntu-desktop --no-install-recommends"
           if [ "$LBOFF" == "y" ] || [ "$LBOFF" == "Y" ]; then
                $INSTALL = "$INSTALL libreoffice-gnome"
           fi ;;
	# Option 4 setup for KDE 4 style desktop with LibreOffice if selected
	4) $INSTALL = " kubuntu-desktop --no-install-recommends"
           if [ "$LBOFF" == "y" ] || [ "$LBOFF" == "Y" ]; then
           	$INSTALL = "$INSTALL libreoffice-kde"
           fi ;;
	# Option 5 - no desktop environment, LibreOffice installed if selected
	5) if [ "$LBOFF" == "y" ] || [ "$LBOFF" == "Y" ]; then
	   	$INSTALL = " libreoffice"
	   fi ;;
	# DEFAULT option - bad desktop selection, same as Option 5
	*) if [ "$LBOFF" == "y" ] || [ "$LBOFF" == "Y" ]; then
                $INSTALL = " libreoffice"
           fi ;;
esac

# Ask about the web browser
read -p "Do you want Firefox Browser (Flash Plugin included)? (y/n)" FFBRS
read -p "Do you want Chromium Browser? (y/n)" CHMBRS

# Concatenate the browser install to the INSTALL string
if [ "$FFBRS" == "y" ] || [ "$FFBRS" == "Y" ]; then
	$INSTALL = "$INSTALL firefox flashplugin-installer"
fi
if [ "$CHMBRS" == "y" ] || [ "$CHMBRS" == "Y" ]; then
	$INSTALL = "$INSTALL chromium-browser"
fi



echo "Super! Now we will start the installation and build the server.\n
This may take between 30 minutes and 3 hours, depending on your internet
connection and the speed of your server.\n
During this time, you should not need to input anything, so go get yourself
a cuppa and relax while you wait.\n

CAUTION! The server will reboot when complete.\n"

# Check to ensure that ready to go
read -p "Are you ready? (y/n)" VERIFYREADY
if [ "$VERIFYREADY" == "n" ] || [ "$VERIFYREADY" == "N" ]; then
        echo "Script Canceled"
        exit 1;
fi



# Start installation of LTSP
echo "Running updates.........."
apt-get update &> ltsp-installer.log
sleep 2
apt-get upgrade -y &> ltsp-installer.log
sleep 3
echo "Installing LTSP.........."
apt-get install ltsp-server -y &> ltsp-installer.log
sleep 3


# Write to Config data to file
echo "Updating and creating configuration files.........."

#DSNmasq config file
echo "
port=0
log-dhcp

tftp-root=/var/lib/tftpboot
dhcp-boot=/ltsp/$ARCH/pxelinux.0
dhcp-option=17,/opt/ltsp/$ARCH
dhcp-option=vendor:PXEClient,6,2b
dhcp-no-override

# PXE menu
pxe-prompt="Press F8 for boot menu", 3

# The known types are x86PC, PC98, IA64_EFI, Alpha, Arc_x86, Intel_Lean_Client, IA32_EFI, BC_EFI, Xscale_EFI and X86-64_EFI
pxe-service=X86PC, "Boot from network", /ltsp/$ARCH/pxelinux
pxe-service=X86PC, "Boot from local hard disk", 0

dhcp-range=$NETADD,proxy
" > /etc/dnsmasq.d/ltsp.conf




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


echo "Building initial LTSP Image.........."
ltsp-build-client --arch $ARCH &> ltsp-installer.log

sleep 5
echo "Installing software to image.........."
chroot /opt/ltsp/$ARCH apt-get install $INSTALL -y &> ltsp-installer.log

sleep 5
echo "Rebuilding the LTSP image.........."
ltsp-update-sshkeys &> ltsp-installer.log
sleep 1
ltsp-update-image &> ltsp-installer.log
sleep 1


echo "Build is complete. Server will reboot in 10 seconds.........."
sleep 10
reboot

exit






