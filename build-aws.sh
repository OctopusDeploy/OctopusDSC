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

POWERSHELL_INSTALLED=0
which powershell > /dev/null
if [ $? != 0 ]; then
  POWERSHELL_INSTALLED=1
  echo "Powershell does not appear to be installed. To install, see https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md."
else
  echo "Powershell installed - good."
fi

check_plugin_installed "vagrant-aws"
check_plugin_installed "vagrant-aws-winrm"
check_plugin_installed "vagrant-dsc"
check_plugin_installed "vagrant-winrm"
check_plugin_installed "vagrant-winrm-syncedfolders"

if [ $POWERSHELL_INSTALLED == 0 ]; then
  echo "Running PSScriptAnalyzer"
read -r -d '' SCRIPT << EOM
Import-Module PSScriptAnalyzer
\$excludedRules = @('PSUseShouldProcessForStateChangingFunctions', 'PSAvoidUsingPlainTextForPassword', 'PSAvoidUsingUserNameAndPassWordParams', 'PSAvoidUsingConvertToSecureStringWithPlainText')
\$results = Invoke-ScriptAnalyzer ./OctopusDSC/DSCResources -recurse -exclude \$excludedRules
write-output \$results
write-output "PSScriptAnalyzer found \$(\$results.length) issues"
exit \$results.length
EOM
  powershell -command "$SCRIPT"
  if [ $? != 0 ]; then
    echo "Aborting as PSScriptAnalyzer found issues."
    exit 1
  fi

  echo "Running Pester Tests"
  powershell -command "Invoke-Pester -OutputFile PesterTestResults.xml -OutputFormat NUnitXml -EnableExit"
  if [ $? != 0 ]; then
    echo "Pester tests failed."
    exit 1
  fi
fi

RANDOM_GUID=$(python -c 'import uuid; print str(uuid.uuid4())')
export KEY_NAME="vagrant_$RANDOM_GUID"

echo "Creating new key-pair $KEY_NAME"
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text --region ap-southeast-2 > $KEY_NAME.pem
if [ $? != 0 ]; then
  echo "Failed to create aws key-pair."
  echo "##teamcity[buildStatus text='{build.status.text}. AWS setup failed.']"
  exit 1
fi

chmod 400 $KEY_NAME.pem

echo "Running 'vagrant up --provider aws'"
time vagrant up --provider aws # --debug &> vagrant.log
VAGRANT_UP_EXIT_CODE=$?
echo "'vagrant up' exited with exit code $VAGRANT_UP_EXIT_CODE"

echo "Running 'vagrant destroy -f'"
vagrant destroy -f
VAGRANT_DESTROY_EXIT_CODE=$?
echo "'vagrant destroy' exited with exit code $VAGRANT_DESTROY_EXIT_CODE"

echo "Removing local key-pair"
rm -f $KEY_NAME.pem

echo "Deleting aws key-pair"
aws ec2 delete-key-pair --key-name $KEY_NAME --region ap-southeast-2

if [ $VAGRANT_UP_EXIT_CODE != 0 ]; then
  echo "Vagrant up failed with exit code $VAGRANT_UP_EXIT_CODE"
  echo "##teamcity[buildStatus text='{build.status.text}. Vagrant failed.']"
  exit $VAGRANT_UP_EXIT_CODE
fi

if [ $VAGRANT_DESTROY_EXIT_CODE != 0 ]; then
  echo "Vagrant destroy failed with exit code $VAGRANT_DESTROY_EXIT_CODE"
  echo "##teamcity[buildStatus text='{build.status.text}. Vagrant cleanup failed. Action required!']"
  exit $VAGRANT_DESTROY_EXIT_CODE
fi
