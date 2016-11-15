#!/bin/bash

function check_plugin_installed() {
    param=$1

    vagrant plugin list | grep -i "$param " > /dev/null

    if [ $? == 0 ]; then
      echo "Vagrant plugin $param exists - good."
    else
      echo "Vagrant plugin $param not installed."
      vagrant plugin install $param
    fi
}

function check_env_var() {
    param=$1
    if [ -z "${!param}" ]; then
        echo "Please set the $param environment variable"
        exit 1
    fi
}

check_env_var AWS_ACCESS_KEY_ID
check_env_var AWS_SECRET_ACCESS_KEY
check_env_var OCTOPUS_SERVER_URL
check_env_var OCTOPUS_API_KEY
check_env_var AWS_SUBNET_ID
check_env_var AWS_SECURITY_GROUP_ID

which vagrant > /dev/null

if [ $? != 0 ]; then
  echo "Please install vagrant from vagrantup.com."
  exit 1
fi

check_plugin_installed "vagrant-aws"
check_plugin_installed "vagrant-aws-winrm"
check_plugin_installed "vagrant-dsc"
check_plugin_installed "vagrant-winrm"
check_plugin_installed "vagrant-winrm-syncedfolders"

time vagrant up --provider virtualbox # --debug &> vagrant.log

echo "Dont forget to run 'vagrant destroy -f' when you have finished"