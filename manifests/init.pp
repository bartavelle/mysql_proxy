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
