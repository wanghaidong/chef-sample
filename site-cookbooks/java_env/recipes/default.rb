#
# Cookbook Name:: java_env
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
directory "#{node['myjava']['root']}" do
    owner         node["myjava"]["user"]
    group         node["myjava"]["group"]
    mode          '0755'
    recursive     true
end

# copy jdk install file to nodes
cookbook_file "#{node['myjava']['download']}/jdk-7u45-linux-i586.tar.gz" do
    source           "jdk-7u45-linux-i586.tar.gz"
    mode             0644
    owner            node["myjava"]["user"]
    group            node["myjava"]["group"]
    action           :create_if_missing
    not_if           {File.exists?("#{node["myjava"]["home"]}/jdk7")}
end

# install neccessory java packages
bash "install_java_packages" do
    user "wang"
    cwd node["myjava"]["download"]
    code <<-EOH
        if ! ls #{node["myjava"]["home"]}/jdk1.7.0_45 > /dev/null 2>&1; then
            tar zxf jdk-7u45-linux-i586.tar.gz
            mv jdk1.7.0_45 #{node["myjava"]["home"]}
            ln -s #{node["myjava"]["home"]}/jdk1.7.0_45 #{node["myjava"]["home"]}/jdk7

            sudo chown -R wang:wang #{node["myjava"]["home"]}/jdk1.7.0_45 #{node["myjava"]["home"]}/jdk7
        fi

        if ! ls apache-maven-3.1.1-bin.tar.gz > /dev/null 2>&1; then
            curl -O http://ftp.jaist.ac.jp/pub/apache/maven/maven-3/3.1.1/binaries/apache-maven-3.1.1-bin.tar.gz
        fi

        if ! ls apache-ant-1.9.2-bin.tar.gz > /dev/null 2>&1; then
            curl -O http://ftp.jaist.ac.jp/pub/apache/ant/binaries/apache-ant-1.9.2-bin.tar.gz
        fi

        sudo chown wang:wang *.tar.gz

        tar zxf apache-maven-3.1.1-bin.tar.gz
        mv apache-maven-3.1.1 #{node["myjava"]["root"]}
        sudo chown -R wang:wang #{node["myjava"]["root"]}/apache-maven-3.1.1
        ln -s #{node["myjava"]["root"]}/apache-maven-3.1.1 #{node["myjava"]["root"]}/maven

        tar zxf apache-ant-1.9.2-bin.tar.gz
        mv apache-ant-1.9.2 #{node["myjava"]["root"]}
        sudo chown -R wang:wang #{node["myjava"]["root"]}/apache-ant-1.9.2
        ln -s #{node["myjava"]["root"]}/apache-ant-1.9.2 #{node["myjava"]["root"]}/ant

        sudo chown -R wang:wang #{node["myjava"]["root"]}/maven
        sudo chown -R wang:wang #{node["myjava"]["root"]}/ant
    EOH
end

template "#{node['myjava']['home']}/.javarc" do
    source 'config/javarc.erb'
    owner  node['myjava']['user']
    group  node['myjava']['group']
    mode   '0644'

    variables(
        :author => 'Haidong Wang'
    )

    not_if { File.exists?("#{node['myjava']['rcfile_path']}")}
end

bash "add javarc to bashrc" do
    user "wang"
    cwd node["myjava"]["home"]
    code <<-EOH
        grep '.javarc' #{node['myjava']['home']}/.bashrc >> /dev/null
        [[ $? -ne 0 ]] && echo "[[ -e #{node['myjava']['rcfile_path']} ]] && source #{node['myjava']['rcfile_path']}" >> #{node['myjava']['home']}/.bashrc

        source #{node['myjava']['rcfile_path']}
    EOH

    only_if do File.exists?("#{node['myjava']['rcfile_path']}") end
end


