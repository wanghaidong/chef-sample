# default attributes

default["myjava"]["user"]       = "wang"
default["myjava"]["group"]      = "wang"

default["myjava"]["home"]  = "/home/#{default['myjava']['user']}"
default["myjava"]["root"]  = "#{default['myjava']['home']}/java"
default["myjava"]["download"] = "#{default['myjava']['home']}/soft"
default["myjava"]["rcfile_name"]  = ".javarc"
default["myjava"]["rcfile_path"]  = "#{default['myjava']['home']}/#{default['myjava']['rcfile_name']}"


