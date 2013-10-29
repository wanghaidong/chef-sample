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

            sudo chown wang:wang apache-maven-3.1.1-bin.tar.gz
        fi

        if ! ls apache-ant-1.9.2-bin.tar.gz > /dev/null 2>&1; then
            curl -O http://ftp.jaist.ac.jp/pub/apache/ant/binaries/apache-ant-1.9.2-bin.tar.gz

            sudo chown wang:wang apache-ant-1.9.2-bin.tar.gz
        fi

        if ! ls #{node["myjava"]["root"]}/apache-maven-3.1.1 > /dev/null 2>&1; then
            tar zxf apache-maven-3.1.1-bin.tar.gz
            mv apache-maven-3.1.1 #{node["myjava"]["root"]}
            sudo chown -R wang:wang #{node["myjava"]["root"]}/apache-maven-3.1.1
            ln -s #{node["myjava"]["root"]}/apache-maven-3.1.1 #{node["myjava"]["root"]}/maven

            sudo chown -R wang:wang #{node["myjava"]["root"]}/maven
        fi

        if ! ls #{node["myjava"]["root"]}/apache-ant-1.9.2 > /dev/null 2>&1; then
            tar zxf apache-ant-1.9.2-bin.tar.gz
            mv apache-ant-1.9.2 #{node["myjava"]["root"]}
            sudo chown -R wang:wang #{node["myjava"]["root"]}/apache-ant-1.9.2
            ln -s #{node["myjava"]["root"]}/apache-ant-1.9.2 #{node["myjava"]["root"]}/ant

            sudo chown -R wang:wang #{node["myjava"]["root"]}/ant
        fi
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
        if ! grep '.javarc' #{node['myjava']['home']}/.bashrc > /dev/null 2>&1; then
            echo "[[ -e #{node['myjava']['rcfile_path']} ]] && source #{node['myjava']['rcfile_path']}" >> #{node['myjava']['home']}/.bashrc
        fi

        source #{node['myjava']['rcfile_path']}
    EOH

    only_if do File.exists?("#{node['myjava']['rcfile_path']}") end
end

# hadoop env install
remote_file "#{node['myjava']['download']}/hadoop-2.2.0.tar.gz" do
    source "http://ftp.jaist.ac.jp/pub/apache/hadoop/common/hadoop-2.2.0/hadoop-2.2.0.tar.gz"
    mode 00644
    owner "wang"
    group "wang"
end


bash "unzip_hadoop_dist" do
    user "wang"
    cwd node["myjava"]["download"]
    code <<-EOH
        if ! ls #{node["myjava"]["home"]}/hadoop-2.2.0  > /dev/null 2>&1; then
            tar zxf hadoop-2.2.0.tar.gz
            mv hadoop-2.2.0 #{node["myjava"]["home"]}
            ln -s #{node["myjava"]["home"]}/hadoop-2.2.0 #{node["myjava"]["home"]}/hadoop

            sudo chown -R wang:wang #{node["myjava"]["home"]}/hadoop-2.2.0 #{node["myjava"]["home"]}/hadoop
        fi
    EOH
end

%W(#{node['myjava']['home']}/hadoop/tmp #{node['myjava']['home']}/hadoop/dfs #{node['myjava']['home']}/hadoop/dfs/name #{node['myjava']['home']}/hadoop/dfs/data).each do |hadoop_dir|
    directory "#{hadoop_dir}" do
        recursive true
        owner  node['myjava']['user']
        group  node['myjava']['group']
        mode   '0755'
        action:create
    end
end

%w(core-site.xml yarn-site.xml hdfs-site.xml mapred-site.xml).each do |hadoop_config_file|
    bash "add_hadoop_path" do
        user "wang"
        cwd node["myjava"]["home"]
        code <<-EOH
            if [ -e #{node['myjava']['home']}/hadoop/etc/hadoop/#{hadoop_config_file} ]; then
                mv -f #{node['myjava']['home']}/hadoop/etc/hadoop/#{hadoop_config_file} #{node['myjava']['home']}/hadoop/etc/hadoop/#{hadoop_config_file}.origin
            fi
        EOH
        # not_if { File.exists?("#{node['myjava']['home']}/hadoop/etc/hadoop/#{hadoop_config_file}.origin")}
    end

    template "#{node['myjava']['home']}/hadoop/etc/hadoop/#{hadoop_config_file}" do
        source "hadoop/#{hadoop_config_file}.erb"
        owner  node['myjava']['user']
        group  node['myjava']['group']
        mode   '0644'

        variables(
            :author            =>    "Haidong Wang",
            :this_ip           =>    "#{node['ipaddress']}",
            :hadoop_tmp        =>    "#{node['myjava']['home']}/hadoop/tmp",
            :hadoop_name_dir   =>    "#{node['myjava']['home']}/hadoop/dfs/name",
            :hadoop_data_dir   =>    "#{node['myjava']['home']}/hadoop/dfs/data",
            :hdfs_port         =>    "54310",
            :hdfs_rep_num      =>    "1"
        )

        not_if { File.exists?("#{node['myjava']['home']}/hadoop/etc/hadoop/#{hadoop_config_file}")}
    end
end

bash "add_hadoop_path" do
    user "wang"
    cwd node["myjava"]["home"]
    code <<-EOH
        if [ -e #{node["myjava"]["home"]}/hadoop ] && [ -e #{node['myjava']['rcfile_path']} ]; then
            if ! grep 'hadoop' #{node['myjava']['rcfile_path']} > /dev/null 2>&1; then
                echo "export PATH=$PATH:#{node['myjava']['home']}/hadoop/sbin:#{node['myjava']['home']}/hadoop/bin" >> #{node['myjava']['rcfile_path']}
            fi
        fi
    EOH
end


