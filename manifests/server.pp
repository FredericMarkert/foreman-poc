# aptkey
define aptkey($ensure, $apt_key_url = 'http://deb.theforeman.org') {
  case $ensure {
    'present': {
      exec { "apt-key present $name":
	command => "/usr/bin/wget -q $apt_key_url/$name -O -|/usr/bin/apt-key add -",
	unless  => "/usr/bin/apt-key list|/bin/grep -c $name",
      }
    }
    'absent': {
      exec { "apt-key absent $name":
	command => "/usr/bin/apt-key del $name",
	onlyif  => "/usr/bin/apt-key list|/bin/grep -c $name",
      }
    }
    default: {
      fail "Invalid 'ensure' value '$ensure' for apt::key"
    }
  }
}

# apt sources
file {'foremanlist':
	path	=> '/etc/apt/sources.list.d/foreman.list',
	ensure	=> present,
	mode	=> 0644,
	content	=> 'deb http://deb.theforeman.org/ precise 1.3'
}

file {'smartproxylist':
	path	=> '/etc/apt/sources.list.d/smartproxy.list',
	ensure	=> present,
	mode	=> 0644,
	content	=> 'deb http://deb.theforeman.org/ precise stable'
}

aptkey { 'foreman.asc':
	ensure	=> present
}

# update and source installation
exec { "apt-update":
	command	=> "/usr/bin/apt-get update",
	require	=> Aptkey['foreman.asc'],
}

package { "foreman-installer":
	ensure	=> "installed",
	require	=> Exec['apt-update'],
}

# seperate installations necessary for proper configuration
package { "bind9":
	ensure	=> "installed",
	require	=> Exec['apt-update'],
}
package { "isc-dhcp-server":
	ensure	=> "installed",
	require	=> Exec['apt-update'],
}

# placing the keyfile
file { "/etc/bind/rndc.key":
	ensure	=> present,
	source	=> "/vagrant/files/BIND/rndc.key",
	owner	=> root,
	group	=> bind,
	mode	=> 640,
	require	=> Package["bind9"],
}

# adding user 'dhcpd' to group 'bind', as this users needs to read the keyfile
user { "dhcpd":
	ensure	=> present,
	groups	=> ['bind'],
	require => [
		Package["isc-dhcp-server"],
		Package["bind9"],
	],
}


# workaround that DHCP can read the keyfile
# replace existing DHCPd-apparmor configuration
service { "apparmor":
    ensure  => "running",
    enable  => "true",
}

file { "/etc/apparmor.d/usr.sbin.dhcpd":
	notify  => Service["apparmor"],
	ensure	=> present,
	owner	=> root,
	group	=> root,
	mode	=> 644,
	source	=> "/vagrant/files/DHCP/apparmor_usr.sbin.dhcpd",
	require => Package["isc-dhcp-server"],
}

# TFTP

# create the TFTP-root directory and set the permissions
file { '/var/lib/tftpboot':
	ensure	=> directory,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
}

# create pxelinux.cfg directory and set the permissions
file { '/var/lib/tftpboot/pxelinux.cfg':
	ensure	=> directory,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	require	=> File["/var/lib/tftpboot"],
}

# netboot image for Ubunu 12.04
file { '/var/lib/tftpboot/ubuntu-12.04':
	ensure	=> directory,
	recurse	=> true,
	purge	=> true,
	force	=> true,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	source	=> "/vagrant/files/TFTP/ubuntu-12.04",
	require	=> File["/var/lib/tftpboot"],
}

# config: list of available boot image
file { '/var/lib/tftpboot/pxelinux.cfg/default':
	ensure	=> present,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	source	=> "/vagrant/files/TFTP/default",
	require	=> File["/var/lib/tftpboot/pxelinux.cfg"],
}

# boot menu text
file { '/var/lib/tftpboot/boot.txt':
	ensure	=> present,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	source	=> "/vagrant/files/TFTP/boot.txt",
	require	=> File["/var/lib/tftpboot"],
}


# options for foreman-installer
file { "/usr/share/foreman-installer/config/answers.yaml":
	ensure	=> present,
	source	=> "/vagrant/files/answers.yaml",
	owner	=> root,
	group	=> root,
	mode	=> 600,
	require	=> Package["foreman-installer"],
}

# modifying foreman-installer to support DDNS
file { "/usr/share/foreman-installer/modules/foreman_proxy/manifests/proxydhcp.pp":
	ensure	=> present,
	source	=> "/vagrant/files/proxydhcp.pp",
	owner	=> root,
	group	=> root,
	mode	=> 644,
	require	=> Package["foreman-installer"],
}


# installation foreman
exec { 'foreman-installer':
	command	=> "/usr/bin/foreman-installer",
	require => [
		Package["bind9"],
		File['/usr/share/foreman-installer/modules/foreman_proxy/manifests/proxydhcp.pp'],
		File['/usr/share/foreman-installer/config/answers.yaml'],
		File["/etc/bind/rndc.key"]
	],
}


# adding user 'foreman-proxy' to group 'bind', as this users needs to read the keyfile
user { "foreman-proxy":
	ensure	=> present,
	groups	=> ['bind'],
	require => Exec["foreman-installer"],
}

# foreman settings
file { "/etc/foreman/settings.yaml":
	ensure	=> present,
	source	=> "/vagrant/files/settings.yaml",
	owner	=> root,
	group	=> foreman,
	mode	=> 640,
	require	=> Exec["foreman-installer"],
}

exec { "foremam-restart":
	command		=> "touch ~foreman/tmp/restart.txt",
	subscribe	=> File["/etc/foreman/settings.yaml"],
	refreshonly	=> true,
	path		=> "/usr/bin/",
}

# HAMMER

# install gem (ruby package manager)
package { 'gem':
	ensure	=> "installed",
}

# install hammer cli
package { 'hammer_cli':
	ensure	=> installed,
	provider => "gem",
	require => Package["gem"],
}

# install foreman plugin for hammer
package { 'hammer_cli_foreman':
	ensure	=> installed,
	provider => "gem",
	require => [
			Package["gem"],
			Package["hammer_cli"],
		],
}

# set up hammer for foreman

# hammer config file
file { "/etc/foreman/cli_config.yml":
	ensure	=> present,
	source	=> "/vagrant/hammer/cli_config.yml",
	require	=> Exec['foreman-installer'],
}

# hammer autocompletion
exec { "autocompletion":
	command	=> "/bin/cp /opt/vagrant_ruby/lib/ruby/gems/1.8/gems/hammer_cli-0.0.14/hammer_cli_complete /etc/bash_completion.d/",
	require	=> [
			Package["hammer_cli_foreman"],
			Exec['foreman-installer'],
		],
}

# hammer logging
file { '/var/log/foreman/hammer.log':
	ensure	=> present,
	mode	=> 777,
	require	=> Exec['foreman-installer'],
}

# foreman configuration via hammer

exec { "hammer execution":
	command	=> "hammer architecture create --name x86_64 \
		&& hammer domain create --name \"local.cloud\" --description \"Base cloud domain\" \
		&& hammer domain update --id 1 --dns-id 1 \
		&& hammer os create --name Ubuntu --major 12 --minor 10 --family Debian --release-name quantal --architecture-ids 1 --ptable-ids 2 --medium-ids 3 \
		&& hammer template update --id 6 --operatingsystem-ids 1 \
		&& hammer template update --id 7 --operatingsystem-ids 1 \
		&& hammer template update --id 2 --operatingsystem-ids 1 \
		&& hammer partition_table update --id 2 --file /vagrant/hammer/pTable \
		&& hammer subnet create --name main --network 172.16.0.0 --mask 255.255.255.0 --gateway 172.16.0.2 --domain-ids 1 --dhcp-id 1 --tftp-id 1 --dns-id 1 \
		&& hammer environment create --name cloud",
	path	=> "/opt/vagrant_ruby/bin/",
	require	=> [
			File["/var/log/foreman/hammer.log"],
			File["/etc/foreman/cli_config.yml"],
			Package["hammer_cli_foreman"],
		],
	user	=> vagrant,
	environment	=> ["HOME=/home/vagrant"],
}



# generate pxe 

# host



# firewall

# uncomment IP forwarding
exec { 'net.ipv4.ip_forward':
	command	=> "/bin/sed -i -e'/#net.ipv4.ip_forward=1/s/^#\\+//' '/etc/sysctl.conf'",
	onlyif	=> "/bin/grep '#net.ipv4.ip_forward=1' '/etc/sysctl.conf' | /bin/grep '^#' | /usr/bin/wc -l",
}

# no restart necessary
exec { 'sysctl':
	command	=> "sysctl -w net.ipv4.ip_forward=1",
	path	=> "/sbin/",
	require	=> Exec["net.ipv4.ip_forward"],
}

# create firewall rules
exec { 'iptables forward':
	command	=> "iptables -P FORWARD ACCEPT",
	path	=> "/sbin",
	require	=> Exec["sysctl"],
}
exec { 'iptables masquerade':
	command	=> "iptables --table nat -A POSTROUTING -o eth0 -j MASQUERADE",
	path	=> "/sbin",
	require	=> Exec["iptables forward"],
}

# preseed iptables-persistent
package{ 'debconf-utils':
	ensure	=> installed,
}
file { '/home/vagrant/iptables-persistent.seed':
	ensure	=> present,
	source	=> "/vagrant/files/iptables-persistent.seed",
}
exec { 'preseed':
	command	=> "debconf-set-selections /home/vagrant/iptables-persistent.seed",
	path	=> "/usr/bin/",
	require	=> [
			Package['debconf-utils'],
			File['/home/vagrant/iptables-persistent.seed'],
		],
}

# install iptables-persistent
package { 'iptables-persistent':
	ensure	=> installed,
	require	=> Exec["iptables masquerade"],
}

# start iptables-persistent
service { "iptables-persistent":
	ensure	=> running,
	require	=> Package["iptables-persistent"],
}



