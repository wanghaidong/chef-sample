#
# Cookbook Name:: common_soft
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
log 'message' do
    message "hello chef for tcserver setup"
    level :info
end

%w(curl unzip tree wget nkf ctags).each do |pkg|
    package pkg do
        action :install
    end
end

