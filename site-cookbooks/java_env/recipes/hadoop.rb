
# hadoop env install
remote_file "#{node['myjava']['download']}/hadoop-2.2.0.tar.gz" do
    source "http://ftp.jaist.ac.jp/pub/apache/hadoop/common/hadoop-2.2.0/hadoop-2.2.0.tar.gz"
    mode 00644
    owner "wang"
    group "wang"
    not_if { File.exists?("#{node['myjava']['download']}/hadoop-2.2.0.tar.gz")}
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
    only_if do File.exists?("#{node['myjava']['download']}/hadoop-2.2.0.tar.gz") end
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
                echo 'export PATH=$PATH:'"#{node['myjava']['home']}/hadoop/sbin:#{node['myjava']['home']}/hadoop/bin" >> #{node['myjava']['rcfile_path']}
            fi
        fi
    EOH
end


