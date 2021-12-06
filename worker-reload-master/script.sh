#!/bin/bash
set -x

i=$clustername

VAULT_ADDR=`yq  read vaultspec.yaml Vault.Address`
VAULT_TOKEN=`yq  read vaultspec.yaml Vault.Token`
vault_Get_secret_path=`yq read vaultspec.yaml Vault.Get_secret_path`

#**********************************************************************************************

if [ ! -d "clusterops_logs" ]  
then
    echo "Directory clusterops_logs DOES NOT exists...Creating"
    mkdir -p clusterops_logs
else
    echo "Directory clusterops_logs is exists...skiping" 
fi

if [ ! -d "clusterops_logs/$i" ]  
then
    echo "Directory clusterops_logs/$i DOES NOT exists...Creating"
    mkdir -p clusterops_logs/$i
else
    echo "Directory clusterops_logs/$i exists...skiping" 
fi

#**********************************************************************************************

if [ ! -d "clusterops_logs" ]  
then
    echo "Directory clusterops_logs DOES NOT exists...Creating"
    mkdir -p clusterops_logs
else
    echo "Directory clusterops_logs is exists...skiping" 
fi

if [ ! -d "clusterops_logs/$i" ]  
then
    echo "Directory clusterops_logs/$i DOES NOT exists...Creating"
    mkdir -p clusterops_logs/$i
else
    echo "Directory clusterops_logs/$i exists...skiping" 
fi

#**********************************************************************************************
source library.sh

vaultLogin
ibmcloudLogin

#**********************************************************************************************

echo "########## Start operation on $i ##########"

clusterLogin
clusterUtilization

vpc=`ibmcloud oc cluster get --cluster $clustername --json | jq -r .vpcs`

#**********************************************************************************************

workerCount=`ibmcloud ks cluster get --cluster=$i --json | jq -r '.workerCount'`
thresholdfloat=`echo 'scale=4;'"($workerCount-1) / $workerCount*100" | bc`
thresholdint=${thresholdfloat%.*}
echo -e "Threshold % per worker node for Utilization is $thresholdint\n"

#**********************************************************************************************

#check for available updates on worker nodes

for j in `ibmcloud ks workers --cluster=$i | awk '{print $1}' | grep kube` 
do
currentversion=`ibmcloud ks worker get --worker $j  --cluster $i --json | jq -r '.kubeVersion' | jq -r '.actual'`
targetversion==`ibmcloud ks worker get --worker $j  --cluster $i --json | jq -r '.kubeVersion' | jq -r '.target'`

#**********************************************************************************************

 if [ $clustercpuutilization -le $thresholdint  ]  && [ $clustermemoryutilization -le $thresholdint ]
 then
 if [ $currentversion = $targetversion ]
 then
	echo "Worker $j is already at latest version"
 else
        echo "Worker $j is at -->> $currentversion"
	if [ $vpc != "null" ]
	then
	   echo "Starting Replace Operation on worker $j"
	else
	   echo "Starting Reload Operation on worker $j"
	fi
	providerapi=`vault kv get -field=apikey $vault_Get_secret_path/$clustername`
	token=`curl -X POST 'https://iam.cloud.ibm.com/identity/token' -H 'Content-Type: application/x-www-form-urlencoded' -d 'grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey='$providerapi''`
	if [ $vpc != "null" ]
    	then
	   echo "worker replace in progress"
	   #curl -X POST "https://containers.cloud.ibm.com/global/v2/replaceWorker" -H  "accept: application/json" -H  "Authorization: Bearer $token" -H  "Content-Type: application/json" -d "{  "cluster": "$clustername",  "update": true,  "workerID": "$j"}"
	   #ibmcloud ks worker replace --cluster=$i --workers=$j 
    	else
	   echo "worker reload in progress"
	   #curl -X PUT "https://containers.cloud.ibm.com/global/v1/clusters/$clustername/workers/$j" -H  "accept: application/json" -H  "Authorization: Bearer $token" -H  "Content-Type: application/json" -d "{  \"action\": \"reload\",  \"force\": true}"
       	   #ibmcloud ks worker reload --cluster=$i --workers=$jq
    	fi
	k=1; while [ "`ibmcloud ks worker get --cluster $i --worker $j --json  | jq -r '.health' | jq -r '.state'`" != "normal" ]; do if [ $k == 1 ] ; then echo "Worker '$j' is reloading"; else echo ".\n" ; fi ; sleep 5s; k=2 ; done
        echo -e "\nWorker $j reload is done ! !"
	echo -e "\nChecking Worker State"
	if 	[ "`ibmcloud ks worker get --cluster $i --worker $j --json  | jq -r '.health' | jq -r '.state'`" != "normal" ]
	then
	 workerstate=`ibmcloud ks worker get --cluster $i --worker $j --json  | jq -r '.health' | jq -r '.state'`
	 echo -e "\nWorker $j state is: $workerstate" &> clusterops_logs/$i/${i}_worker_${j}_${log_start}.log
	 exit
	else
	 echo "Worker $j state is normal"
	fi
  fi
 fi
 done
