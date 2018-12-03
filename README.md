Installer for the [lancache](https://github.com/zeropingheroes/lancache) by [Nexusofdoom](https://github.com/nexusofdoom), [Zero Ping Heroes](https://github.com/zeropingheroes) and [Geoffrey](https://github.com/bntjah)

Improve download speeds and reduce strain on your Internet connection at LAN parties. Locally cache game installs and updates from the largest distributors.
  
 ##### Ubuntu 18.04.1 with OpenSSH Server.
 
 ##### Download url for Ubuntu 18.04.1 Server  
  http://cdimage.ubuntu.com/releases/18.04.1/release/ubuntu-18.04.1-server-amd64.iso
 
 ##### You will need 18 avaliable IP's example 192.168.0.2 - 192.168.0.20 used for lancache
 
 
# Clone the git repo
 
 `git clone -b master http://github.com/nexusofdoom/lancache-installer`
 
 `cd lancache-installer`
 
# Run installer with sudo

### Run 
 `sudo ./install-lancache.sh`
 
##########################################################################
 
 To access netdata 
 open broswer and navigate to http://your-primary-ip:19999
 
##########################################################################

# Change IP Addressing for a new network
### Run
`sudo ./changeip.sh`