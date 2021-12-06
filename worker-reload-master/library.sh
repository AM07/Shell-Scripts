#!/bin/bash
#set -x

#**********************************************************************************************

#VAULT_ADDR=`yq  read vaultspec.yaml Vault.Address`
#VAULT_TOKEN=`yq  read vaultspec.yaml Vault.Token`
#vault_Get_secret_path=`yq read vaultspec.yaml Vault.Get_secret_path`

vaultLogin () {
    cluster_config_path=`pwd`
    DATE=`date +"%Y%m%d_%H%M%S"`
    log_start="$(date +"%Y-%m-%d-%H.%M.%S")"
    VAULT_ADDR=`yq  read vaultspec.yaml Vault.Address`
    VAULT_TOKEN=`yq  read vaultspec.yaml Vault.Token`
    vault_Get_secret_path=`yq read vaultspec.yaml Vault.Get_secret_path`
    export VAULT_ADDR
    export VAULT_TOKEN
    export vault_Get_secret_path
    vault status &> clusterops_logs/vault_${log_start}.log
    if [ $? -eq 0 ]
    then
        echo "Vault login Success" 
    else
        echo "Vault login Unsuccess..Please check the logs at clusterops_logs/vault_${log_start}.log"
        exit
    fi  
}

#**********************************************************************************************

ibmcloudLogin () {
providerapi=`vault kv get -field=apikey $vault_Get_secret_path/$clustername`
ibmcloud login --apikey $providerapi --no-region &> clusterops_logs/ibmcloudlogin_${log_start}.log
if [ $? -eq 0 ]
    then
        echo "ibmcloud login Success" 
    else
        echo "ibmcloud login Unsuccess..Please check the logs at clusterops_logs/ibmcloudlogin_${log_start}.log"
        exit
    fi
}

#**********************************************************************************************

clusterLogin () { 
#provider=`yq  read userspec.yaml Cluster.Provider`
# cloudprovider=$provider
# case $cloudprovider in
#   ibmcloud)
#       if [ $cloudprovider = "ibmcloud" ]
#       then
      echo "cluster is hosted on IBM Cloud"
      echo "Calling the cluster login function for IBM Cloud"
      providerapi=`vault kv get -field=apikey $vault_Get_secret_path/$clustername`
      cluster_url=`vault kv get -field=url $vault_Get_secret_path/$clustername`
      log_start="$(date +"%Y-%m-%d-%H.%M.%S")"
      ibmcloud oc cluster config -c $clustername
      oc login -u apikey -p $providerapi $cluster_url &> clusterops_logs/$i/${i}_clusterlogin_${log_start}.log
      
#        if [ $? -eq 0 ]
#        then
#           echo "Cluster login Success"
#        else
#           echo "Cluster login Unsuccess..Please check the logs at clusterops_logs/$i/${i}_clusterlogin_${log_start}.log"
#           exit
#        fi
#        fi
#       else
#        echo "Not a valid provider"
#        exit
#        ;;
# esac
if [ $? -eq 0 ]
    then
        echo "Cluster login Success"
    else
        echo "Cluster login Unsuccess..Please check the logs at clusterops_logs/$i/${i}_clusterlogin_${log_start}.log"
        exit
fi
}

#**********************************************************************************************

clusterUtilization() {
declare -i cpurequesttotall=0
declare -i cpuutilizationtotall=0
declare -i memoryrequesttotall=0
declare -i memoryutilizationtotall=0

for k in `oc get nodes --no-headers | awk '{print$1}'`
do
	cpurequest=`oc describe nodes $k | grep  -A 3 -e "^\\s*Resource" | awk '{print$3}'| sed -n 3p | awk '{print substr($0, 2, length($0) - 2)}'|sed 's/.$//'`
	cpurequesttotall=`expr "$cpurequesttotall" + "$cpurequest"`
	cpuutilization=`kubectl top nodes $k --no-headers=true | awk '{print$3}' |sed 's/.$//'`
	cpuutilizationtotall=`expr "$cpuutilizationtotall" + "$cpuutilization"`
	if [ $cpurequesttotall -gt $cpuutilizationtotall ]
      then
	  		clustercpuutilization=$cpurequesttotall
      else
	        clustercpuutilization=$cpuutilizationtotall
    fi
	memoryrequest=`oc describe nodes $k | grep  -A 3 -e "^\\s*Resource" | awk '{print$3}'| sed -n 4p | awk '{print substr($0, 2, length($0) - 2)}'|sed 's/.$//'`
	memoryrequesttotall=`expr "$memoryrequesttotall" + "$memoryrequest"`
	memoryutilization=`kubectl top nodes $k --no-headers=true | awk '{print$5}' |sed 's/.$//'`
	memoryutilizationtotall=`expr "$memoryutilizationtotall" + "$memoryutilization"`
	if [ $memoryrequesttotall -gt $memoryutilizationtotall ]
      then
	  		clustermemoryutilization=$memoryrequesttotall
      else
	        clustermemoryutilization=$memoryutilizationtotall
    fi
done
echo -e " clustercpuutilization: $clustercpuutilization \n clustermemoryutilization: $clustermemoryutilization"
}

#**********************************************************************************************

