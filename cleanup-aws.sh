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
check_env_var AWS_SUBNET_ID
check_env_var AWS_SECURITY_GROUP_ID

which vagrant > /dev/null
if [ $? != 0 ]; then
  echo "Please install vagrant from vagrantup.com."
  exit 1
fi
echo "Vagrant installed - good."

which aws > /dev/null
if [ $? != 0 ]; then
  echo "Please install aws-cli. See http://docs.aws.amazon.com/cli/latest/userguide/installing.html."
  exit 1
fi
echo "AWS CLI installed - good."

check_plugin_installed "vagrant-aws"
check_plugin_installed "vagrant-aws-winrm"
check_plugin_installed "vagrant-dsc"
check_plugin_installed "vagrant-winrm"
check_plugin_installed "vagrant-winrm-syncedfolders"

#get key name from file
shopt -s nullglob
files=(vagrant_*.pem)

if [ ${#files[@]} -eq 0]; then
  echo "No key pair (vagrant_GUID.pem) found - unable to cleanup."
  exit 1
fi

export KEY_NAME=${files[0]%.*}
echo "Using key pair $KEY_NAME.pem"

#todo: check vagrant status and exit cleanly if not running

echo "Running 'vagrant destroy -f'"
vagrant destroy -f
VAGRANT_DESTROY_EXIT_CODE=$?
echo "'vagrant destroy' exited with exit code $VAGRANT_DESTROY_EXIT_CODE"

echo "Removing local key-pair"
rm -f $KEY_NAME.pem

echo "Deleting aws key-pair"
aws ec2 delete-key-pair --key-name $KEY_NAME --region ap-southeast-2

if [ $VAGRANT_DESTROY_EXIT_CODE != 0 ]; then
  echo "Vagrant destroy failed with exit code $VAGRANT_DESTROY_EXIT_CODE"
  echo "##teamcity[buildStatus text='{build.status.text}. Vagrant cleanup failed. Action required!']"
  exit $VAGRANT_DESTROY_EXIT_CODE
fi
