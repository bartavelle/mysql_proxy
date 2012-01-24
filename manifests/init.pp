/*
=Class: mysql_proxy

This class installs and configures the mysql_proxy product. It currently only works for Ubuntu lucid (10.04), and is an ugly hack. It is however pretty useful in several scenarios.

==Parameters:
+rules+:: An associative array describing the rules, where the key is the request mask (see next part) and the value is either +multi+ or +single+. +single+ means that the request is not supposed to return more than one line.
+admin_port+:: port of the administration interface, currently not used
+admin_password+:: password for the administration interface (not used)
+proxy_port+:: the port the proxy will listen on (defaults to 4050)
+mysql_ip+:: the ip address of the actual mysql server (defaults to 127.0.0.1)
+mysql_port+:: the port of the actual mysql server (defaults to 3306)

==Rules format
The rules must be formated like the output of the tokenizer.normalize function. You should check the logfile to be sure of what to expect.

==Sample Usage:

  class { 'mysql_proxy': rules => {
    'SELECT `*` FROM `table` ' => 'multi',
    'ROLLBACK ' => 'single',
    'SELECT `*` FROM `user` WHERE `username` = ? ' => 'single' }
  }

==Usage
Once installed, the proxy will listen to incoming connections and forward them to the MySQL server. Rejected requests will be logged in their normalized form on syslog, with facility daemon and level alert.

*/
class mysql_proxy($rules, $admin_port=4045, $admin_password='not_used', $proxy_port=4050, $mysql_ip='127.0.0.1', $mysql_port=3306)
{
    group { 'mysqlproxy': ensure => 'present'; }
    user { 'mysqlproxy': shell => '/bin/false', password => '!', gid => 'mysqlproxy'; }
    File { owner => 'root', group => 'root', mode => 640, require => Package['mysql-proxy'] }

    case $operatingsystem {
        'Ubuntu': { case $lsbdistcodename {
            'lucid':  { include mysql_proxy::distro::lucid }
            default: { fail("Unsupported distribution $lsbdistcodename") }
            }
        }
        'rspec': { }
        default: { fail("Unsupported operating system $operatingsystem") }
    }
    
    file {
        '/var/log/mysql-proxy': ensure => directory, mode => 755, owner => 'mysqlproxy', group => 'adm';
        '/etc/default/mysql-proxy': source => 'puppet:///modules/mysql_proxy/default';
        '/etc/mysql/proxy.cnf': content => template('mysql_proxy/proxy.cnf.erb');
        '/usr/lib/mysql-proxy/lua/cachefilter.lua': content => template('mysql_proxy/cachefilter.lua.erb'), group => 'mysqlproxy';
    }
}
