# https://www.varnish-cache.org/installation/redhat
execute "varnish-cache.org" do
  command "rpm -q varnish || rpm --nosignature -i https://repo.varnish-cache.org/redhat/varnish-4.0.el6.rpm"
end

package "varnish" do
  action :install
end

service "varnish" do
  action [:enable, :start]
end

service "varnishlog" do
  action [:disable, :start]
end

service "varnishncsa" do
  action [:disable, :start]
end

execute "service varnish restart" do
  action :nothing
end

template "/etc/varnish/default.vcl" do
  action :create
  source "../isucon4y/default.vcl"
  notifies :run, "execute[service varnish restart]"
end

template "/etc/sysconfig/varnish" do
  action :create
  source "../isucon4y/sysconfig_varnish"
  notifies :run, "execute[service varnish restart]"
end
