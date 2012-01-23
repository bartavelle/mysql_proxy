class mysql_proxy::distro::lucid
{
    package { ['mysql-proxy','libglib2.0-0']: ensure => latest, require => [Pinning['mysql-proxy-natty'],User['mysqlproxy']]; }
    pinning { 'mysql-proxy-natty': packages => ['mysql-proxy','libglib2.0-0','libpcre3'], distro => 'natty'; }
    file {
        '/etc/init/mysql-proxy.conf': source => 'puppet:///modules/mysql_proxy/mysql-proxy.conf';
        '/usr/lib/mysql-proxy/lua/lsyslog.so': source => 'puppet:///modules/mysql_proxy/lsyslog.so', owner => 'root', group => 'root', mode => '755', require => Package['mysql-proxy'];
        '/etc/init.d/mysql-proxy': ensure => absent;
    }
}
