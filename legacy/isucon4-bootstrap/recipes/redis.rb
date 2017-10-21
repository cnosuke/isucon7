package "redis" do
  options "--enablerepo=epel -y"
  action :install
end

service "redis" do
  action [:enable, :start]
end

execute "service redis restart" do
  action :nothing
end

template "/etc/redis.conf" do
  action :create
  source "../isucon4y/redis.conf"
  notifies :run, "execute[service redis restart]"
end
