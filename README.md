#UNIX_Scripts
UNIX scripts for setup and process automation.


##sambasetup.sh
This script is designed to build the full Samaba from source and configure as a
Windows Active Directory at 2008 R2 level, and shared folders.
This was tested with a headless Ubuntu Server 14.04 LTS, Samaba 4.1.11 Source.
Testing and deployment of the AD DS and Shared folders was successfully completed
within a corporate environment.

##ltsp-setup.sh
This script is used to setup LTSP on Ubuntu Server using ProxyDHCP (as described
in the Ubuntu documentation), within a network preconfigured with DHCP servers.
This script allows for the setup of i386 and amd64 architecture, Unity, Gnome,
LXDE and KDE desktop environments, LibreOffice, Firefox and Chromium (not Google's Chrome).

At the moment, this script has not yet been fully tested, but will be gradually expanded
and updated as testing is undertaken over the next few weeks.


Feel free to make suggestions and comment on any errors found.
