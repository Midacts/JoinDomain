#!/bin/bash
# Active Directory Integration Setup Script
# Date: 1st of April, 2014
# Version 1.0
#
# Author: John McCarthy
# Email: midactsmystery@gmail.com
# <http://www.midactstech.blogspot.com> <https://www.github.com/Midacts>
#
# To God only wise, be glory through Jesus Christ forever. Amen.
# Romans 16:27, I Corinthians 15:1-4
#---------------------------------------------------------------
######## FUNCTIONS ########
function installKerberos()
{
	# Installs the required packages for Kerberos
		echo
		echo -e '\e[01;34m+++ Installing the Kerberos packages...\e[0m'
		echo
		apt-get update
		apt-get install -y krb5-user libpam-krb5
		echo
		echo -e '\e[01;37;42mThe Kerberos packages were successfully installed!\e[0m'
		echo
}
function configureKerberos()
{
	# Gets the domain and domain controller's names
		echo -e '\e[33mPlease type in the name of your domain:\e[0m'
		echo -e '\e[33;01mFor Example:  example.com\e[0m'
		read domain
		echo
		echo -e '\e[33mPlease type in the name of your domain controller:\e[0m'
		echo -e '\e[33;01mFor Example:  dc.example.com\e[0m'
		read dc
	# Sets the variables to upper and lower case
		dom_low=$( echo "$domain" | tr -s  '[:upper:]'  '[:lower:]' )
		dom_up=$( echo "$domain" | tr -s  '[:lower:]' '[:upper:]' )
		dc_up=$( echo "$dc" | tr -s  '[:lower:]' '[:upper:]' )

		echo
		echo -e '\e[01;34m+++ Editing the Kerberos configuration file...\e[0m'
		cat <<EOA> /etc/krb5.conf
[libdefaults]
        clock-skew              = 300
        default_realm           = $dom_up
        dns_lookup_realm        = true
        dns_lookup_kdc          = true
        forwardable             = true
        proxiable               = true
        ticket_lifetime         = 24000
        default_tgs_enctypes    = rc4-hmac aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96
        default_tkt_enctypes    = rc4-hmac aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96
        permitted_enctypes      = rc4-hmac aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96

[realms]
        $dom_up = {
                kdc             = $dc_up
                admin_server    = $dc_up
                default_domain  = $dom_up
        }

[domain_realm]
        .$dom_low	        = $dom_up
       $dom_low	        = $dom_up

[login]
        krb4_convert            = true
        krb4_get_tickets        = false

[logging]
        default                 = /var/log/krb5libs.log
        kdc                     = /var/log/kdc.log
        admin_server            = /var/log/kadmind.log
EOA
		echo
		echo -e '\e[01;37;42mThe Kerberos configuration file has been successfully edited!\e[0m'
		echo
}
function installSamba()
{
	# Installs the samba package
		echo
		echo -e '\e[01;34m+++ Installing the Samba package...\e[0m'
		echo
		apt-get install -y samba
		echo
		echo -e '\e[01;37;42mThe Samba package was successfully installed!\e[0m'
		echo
}
function configureSamba()
{
	# Verifies that the dom variable is set
		if [[ -z "$domain" ]]; then
		# Gets the domain and domain controller's names
			echo -e '\e[33mPlease type in the name of your domain:\e[0m'
			echo -e '\e[33;01mFor Example:  example.com\e[0m'
			read domain
			echo
			echo -e '\e[33mPlease type in the name of your domain controller:\e[0m'
			echo -e '\e[33;01mFor Example:  dc.example.com\e[0m'
			read dc
		# Sets the variables to upper and lower case
			dom_low=$( echo "$domain" | tr -s  '[:upper:]'  '[:lower:]' )
			dom_up=$( echo "$domain" | tr -s  '[:lower:]' '[:upper:]' )
			dc_up=$( echo "$dc" | tr -s  '[:lower:]' '[:upper:]' )
		fi
			dom_short=$(echo $dom_up | awk 'match($0,"\."){print substr($0,RSTART-99,99)}')
	# Edits the smb.conf file
		echo
		echo -e '\e[01;34m+++ Editing the Samba configuration file...\e[0m'
		cat <<EOB> /etc/samba/smb.conf
[global]

  security                              = ads
  workgroup                             = $dom_short
  realm                                 = $dom_up
  password server                       = $dc_up
  kerberos method                       = secrets and keytab
  log file                              = /var/log/samba/%m.log
  template homedir                      = /home/%D/%U
  template shell                        = /bin/bash
  encrypt passwords                     = Yes
  client signing                        = Yes
  client use spnego                     = Yes
  winbind separator                     = +
  winbind enum users                    = Yes
  winbind enum groups                   = Yes
  winbind use default domain            = Yes
  winbind refresh tickets               = Yes
  idmap config ORTHOBANC : schema_mode  = rfc2307
  idmap config ORTHOBANC : range        = 10000000-29999999
  idmap config ORTHOBANC : default      = Yes
  idmap config ORTHOBANC : backend      = rid
  idmap config * : range                = 20000-29999
  idmap config * : backend              = tdb

[sysvol]

  path                                  = /var/lib/samba/sysvol
  read only                             = no

[netlogon]

  path                                  = /var/lib/samba/sysvol/$dom_up/scripts
  read only                             = no
EOB
		echo
		echo -e '\e[01;37;42mThe Samba configuration file has been successfully edited!\e[0m'

	# Restarts the samba service
		echo
		echo -e '\e[01;34m+++ Restarting the Samba service...\e[0m'
		echo
		service samba restart
		echo
		echo -e '\e[01;37;42mThe Samba service has been successfully restarted!\e[0m'
		echo
}
function installWinbind()
{
	# Installs winbind
		echo
		echo -e '\e[01;34m+++ Installing the Winbind package...\e[0m'
		echo
		apt-get install -y winbind
		echo
		echo -e '\e[01;37;42mThe Winbind package was successfully installed!\e[0m'
		echo
}
function configureWinbind()
{
	# Configures the use of winbind by editing /etc/nsswitch.conf
		echo
		echo -e '\e[01;34m+++ Editing the nsswitch configuration file...\e[0m'
		cat <<EOC> /etc/nsswitch.conf
passwd:         compat winbind
group:          compat winbind
shadow:         compat winbind

hosts:          files dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis
EOC
		echo
		echo -e '\e[01;37;42mThe nsswitch configuration file has been successfully edited!\e[0m'
		echo
}
function joinDomain()
{
	# Joins the machine to the Active Directory domain
		echo
		echo -e '\e[33;01mPlease type in the name of the user you would like to use to join your domain:\e[0m'
		read user
		echo -e '\e[33;01mPlease type in that user'\''s password:\e[0m'
		read passwd
		echo
		echo -e '\e[01;34m+++ Joining your Active Directory domain...\e[0m'
		echo
		/usr/bin/net ads join -U"$user"%"$passwd"
		echo
		echo -e '\e[01;37;42mYou have successfully joined your Active Directory domain!\e[0m'
		echo
	# Restarts the samba and winbind service
		echo -e '\e[01;34m+++ Restarting the Samba and Winbind services...\e[0m'
		echo
		service samba restart
		service winbind restart
		echo
		echo -e '\e[01;37;42mThe Samba and Winbind services have been successfully restarted!\e[0m'
		echo
}
function pam()
{
	# Edits the /etc/pam.d/common-account file
		echo
		echo -e '\e[01;34m+++ Editing the /etc/pam.d/commin-account file...\e[0m'
		cat <<EOD> /etc/pam.d/common-account
account sufficient       pam_winbind.so
account required         pam_unix.so
EOD
		echo
		echo -e '\e[01;37;42mYou have successfully edited the /etc/pam.d/common-account file!\e[0m'

	# Edits the /etc/pam.d/common-auth file
		echo
		echo -e '\e[01;34m+++ Editing the /etc/pam.d/commin-auth file...\e[0m'
		cat <<EOE> /etc/pam.d/common-auth
auth sufficient pam_winbind.so
auth sufficient pam_unix.so nullok_secure use_first_pass
auth required   pam_deny.so
EOE
		echo
		echo -e '\e[01;37;42mYou have successfully edited the /etc/pam.d/common-auth file!\e[0m'

	# Edits the /etc/pam.d/common-session file
		echo
		echo -e '\e[01;34m+++ Editing the /etc/pam.d/commin-session file...\e[0m'
		cat <<EOF> /etc/pam.d/common-session
session required pam_unix.so
session required pam_mkhomedir.so umask=0022 skel=/etc/skel
EOF
		echo
		echo -e '\e[01;37;42mYou have successfully edited the /etc/pam.d/common-session file!\e[0m'
		echo
}
function sudo()
{
	# Install sudo
		echo
		echo -e '\e[01;34m+++ Installing the sudo package...\e[0m'
		echo
		apt-get install -y sudo
		echo
		echo -e '\e[01;37;42mYou have successfully installed the sudo package!\e[0m'

	# Makes the default home directory
		echo
		echo -e '\e[01;34m+++ Creating your domain'\''s home directory...\e[0m'
		dom_search=$(grep -r "workgroup" /etc/samba/smb.conf)
		dom_short=$(echo $dom_search | awk 'match($0,"="){print substr($0,RSTART+2,99)}')
		mkdir /home/$dom_short
		echo
		echo -e '\e[01;37;42mYou have successfully created your domain'\''s home directory!\e[0m'

	# Edits the /etc/pam.d/sudo file
		echo
		echo -e '\e[01;34m+++ Editing the /etc/pam.d/sudo file...\e[0m'
		cat <<EOG> /etc/pam.d/sudo
auth sufficient pam_winbind.so
auth sufficient pam_unix.so use_first_pass
auth required   pam_deny.so

@include common-auth
@include common-account
@include common-session-noninteractive
EOG
		echo
		echo -e '\e[01;37;42mYou have successfully edited the /etc/pam.d/sudo file!\e[0m'

	# Edits the /etc/sudoers file
		echo
		echo -e '\e[01;34m+++ Editing the /etc/sudoers file...\e[0m'
		cat <<EOH> /etc/sudoers
Defaults	env_reset
Defaults	mail_badpass
Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# User privilege specification
root	ALL=(ALL:ALL) ALL

# Allow members of group sudo to execute any command
%sudo	ALL=(ALL:ALL) ALL

# Grant's access to the Domain Admins Active Directory Security Group
%domain\ admins        ALL=(ALL) ALL
EOH
		echo
		echo -e '\e[01;37;42mYou have successfully edited the /etc/sudoers file!\e[0m'
}
function doAll()
{
	# Calls Function 'installKerberos'
		echo -e "\e[33m=== Install Kerberos ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				installKerberos
		fi

	# Calls Function 'configureKerberos'
		echo -e "\e[33m=== Configure the Kerberos configuration file ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				configureKerberos
		fi

	# Calls Function 'installSamba'
		echo -e "\e[33m=== Install Samba ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				installSamba
		fi

	# Calls Function 'configureSamba'
		echo -e "\e[33m=== Configure the Samba configuration file ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				configureSamba
		fi

	# Calls Function 'installWinbind'
		echo -e "\e[33m=== Install Winbind ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				installWinbind
		fi

	# Calls Function 'configureWinbind'
		echo -e "\e[33m=== Configure the nsswitch configuration file ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				configureWinbind
		fi

	# Calls Function 'joinDomain'
		echo -e "\e[33m=== Join the Active Directory domain ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				joinDomain
		fi

	# Calls Function 'pam'
		echo -e "\e[33m=== Configure PAM's configuration files ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				pam
		fi

	# Calls Function 'sudo'
		echo -e "\e[33m=== Configure the sudo configuration files ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				sudo
		fi
		
	# End of Script Congratulations, Farewell and Additional Information
		clear
		FARE=$(cat << 'EOZ'


        \e[01;37;42mWell done! You have completed your AD Integration Installation!\e[0m
    \e[31;01mNOTE: "domain admins" was the only group added to the /etc/sudoers file\e[0m

  \e[30;01mCheckout similar material at midactstech.blogspot.com and github.com/Midacts\e[0m

                            \e[01;37m########################\e[0m
                            \e[01;37m#\e[0m \e[31mI Corinthians 15:1-4\e[0m \e[01;37m#\e[0m
                            \e[01;37m########################\e[0m
EOZ
)

		#Calls the End of Script variable
		echo -e "$FARE"
		echo
		echo
		exit 0
}

# Check privileges
[ $(whoami) == "root" ] || die "You need to run this script as root."

# Welcome to the script
clear
echo
echo
echo -e '             \e[01;37;42mWelcome to Midacts Mystery'\''s AD Integration Installer!\e[0m'
echo
echo
case "$go" in
        * )
                        doAll ;;
esac

exit 0
