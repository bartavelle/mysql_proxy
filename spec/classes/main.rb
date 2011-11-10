require 'spec_helper'

def filecontent(fname)
    out = ''
    File.open 'spec/filesamples/' + fname, (File::RDONLY | File::NONBLOCK) do |io|
        out = io.read(1024*1024*1024)
    end
    out
end


describe 'mysql_proxy', :type => :class do
    let(:title) { 'mysql_proxy' }
    let(:node) { 'testproxy.site.com' }

    filelist = []

    describe "standard configuration" do
        let(:facts) { {
            'operatingsystem' => 'rspec',
        } }

        let(:params) { {
            :rules => {
                'SELECT `*` FROM `table` ' => 'multi',
                'ROLLBACK ' => 'single',
                'SELECT `*` FROM `user` WHERE `username` = ? ' => 'single',
            }
        } }

        it { should contain_file('/etc/mysql/proxy.cnf').with_content(filecontent('proxy.cnf')) }
        it { should contain_file('/usr/lib/mysql-proxy/lua/cachefilter.lua').with_content(filecontent('cachefilter.lua')) }
    end
end
