class mysql_proxy($rules, $admin_port=4045, $admin_password='not_used', $proxy_port=4050, $mysql_ip='127.0.0.1', $mysql_port=3306)
{
    user { 'mysqlproxy': shell => '/bin/false', password => '!'; }
    pinning { 'mysql-proxy-natty': packages => ['mysql-proxy','libglib2.0-0','libpcre3'], distro => 'natty'; }
    package { ['mysql-proxy','libglib2.0-0']: ensure => latest, require => [Pinning['mysql-proxy-natty'],User['mysqlproxy']]; }
    File { owner => 'root', group => 'root', mode => 640, require => Package['mysql-proxy'] }
    file {
        '/var/log/mysql-proxy': ensure => directory, mode => 755, owner => 'mysqlproxy', group => 'adm';
        '/etc/default/mysql-proxy': source => 'puppet:///modules/mysql_proxy/default';
        '/etc/init/mysql-proxy.conf': source => 'puppet:///modules/mysql_proxy/mysql-proxy.conf';
        '/etc/init.d/mysql-proxy': ensure => absent;
        '/etc/mysql/proxy.cnf': content => template('mysql_proxy/proxy.cnf.erb');
        '/usr/lib/mysql-proxy/lua/cachefilter.lua': content => template('mysql_proxy/cachefilter.lua.erb');
    }
}
