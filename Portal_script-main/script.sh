echo -e "

***********************************************************************
*								      *
*		Basic installation of Portal			      *
*								      *
*********************************************************************** 

____ _____ ___ ___
|      |   |   |  |          *
|___   |   |_  |__|         **      ---   IIM Installation
   |   |   |   |             *
___|   |   |__ |            ***  
		     
";

a=`getopt -o d::,s:: --long dry-run::,short:: -- "$@"`
while true;
do
  case $1 in
   -d|--dry-run) 
	         b="-dry";
		 break ;;
    *) break ;;
  esac
done

read -p "Enter the binary location (Default: /opt/IBM/portal/SETUP): " binariespath;
export binariespath=`echo "${binariespath:-/opt/IBM/portal/SETUP}"`
echo " ";

echo "Please choose your OS type from below list";
PS3=$'\n'"Your choice: "
options=("aix" "linux_ppc" "linux_ppc64le" "linux_x86_64" "win64" "Quit running script if needed to be checked")
echo " ";
select opt in "${options[@]}"
do
    case $opt in
        "aix" | "linux_ppc" | "linux_ppc64le" | "linux_x86_64" | "win64")
            echo "you chose $opt"$'\n';
            export OS="$opt"
	    break
            ;;
        "Quit running script if needed to be checked")
            exit
            ;;
        *) echo "The option is invalied, choose a valid OS type from the list provided";;
    esac
    echo " ";
done
echo " ";

echo " ";
read -p "Enter the imcl path for IIM installation (Default: $binariespath/IIM/$OS/): " imclforiiminstall;
export imclforiiminstall=`echo "${imclforiiminstall:-$binariespath/IIM/$OS/}"`
echo " ";

read -p "Enter the path for IIM Installation directory (Default: /opt/IBM/InstallationManager): " iiminstallationpath;
export iiminstallationpath=`echo "${iiminstallationpath:-/opt/IBM/InstallationManager}"`
if [ "$b" = "-dry" ]
then
 echo $'\n'"Directory will be created at $iiminstallationpath";
else
 mkdir -p $iiminstallationpath;
fi
echo " ";

echo -e " \033[32m
***** INSTALLING IIM PLEASE WAIT *****
\033[0m
"
if [ "$b" = "-dry"]
then
 echo "$imclforinstall/tools/imcl install com.ibm.cic.agent -repositories $imclforiiminstall/repository.config -installationDirectory $iiminstallationpath -acceptLicense -showProgress runs here...."$'\n'
else
 $imclforiiminstall/tools/imcl install com.ibm.cic.agent -repositories $imclforiiminstall/repository.config -installationDirectory $iiminstallationpath -acceptLicense -showProgress
export imclinstalledpath="$iiminstallationpath/eclipse/tools/";
fi

echo -e "
____ _____ ___ ___
|      |   |   |  |          **
|___   |   |_  |__|            *     --- Install base version of packages
   |   |   |   |             ***
___|   |   |__ |             *
	                     ***

"

read -p "Enter the path for WASND, Java & Portal Installation directory (Default: /opt/IBM/WebSphere): " wasportaldirectories;
export wasportaldirectories=`echo "${wasportaldirectories:-/opt/IBM/WebSphere}"`
echo " ";

read -p "Enter the path for saving the installation responce files: " responcefilepath;
echo " ";

read -p "Enter the path for IMShared (Default: /opt/IBM/): " imsharelocation;
export imsharelocation=`echo "${imsharelocation:-/opt/IBM}"`
echo " ";

read -p "Enter the username for Config wizard console (Default: wpsadmin): " cwusername;
export cwusername=`echo "${cwusername:-wpsadmin}"`
echo " ";

echo "(Note: Make sure take note of the password)"
read -p  "Enter the password for Config wizard console (Default: wpsadmin): " -s cwpassword;
export cwpassword=`echo "${cwpassword:-wpsadmin}"`
export encwpasswd=`echo "$cwpassword" | base64`;
echo " ";

read -p "Enter the username for WPS console (Default: wpsadmin): " wpsusername;
export wpsusername=`echo "${wpsusername:-wpsadmin}"`
echo " ";

echo "(Note: Make sure take note of the password)"
read -p "Enter the password for WPS Console: " -s wpspassword;
export wpspassword=`echo "${wpspassword:-wpspassword}"`
export enwpspasswd=`echo "$wpspassword" | base64`;
echo " ";

if [ "$b" = "-dry" ]
then
 echo "Base install responce will be created at $responcefilepath/WP90_pt1_server_full_install.xml";
else
cat << 	EOF > $responcefilepath/WP90_pt1_server_full_install.xml

<?xml version='1.0' encoding='UTF-8'?>
<agent-input>
  <variables>
    <variable name='sharedLocation' value='$imsharelocation/IMShared'/>
  </variables>
  <server>
    <repository location='$binariespath/products/WASND90/repository.config'/>
    <repository location='$binariespath/products/JDK803/repository.config'/>
    <repository location='$binariespath/products/WP85_Server/repository.config'/>
    <repository location='$binariespath/products/IFPI59896/8.5.0.0-WP-Server-IFPI59896.zip'/>
  </server>
  <profile id='IBM WebSphere Application Server V9.0' installLocation='$wasportaldirectories/AppServer'>
    <data key='cic.selector.nl' value='en, fr, it, zh, ro, ru, zh_TW, de, ja, pl, es, cs, hu, ko, pt_BR, zh_HK'/>
  </profile>
  <install>
    <!-- IBM WebSphere Application Server Network Deployment  9.0.0.2 -->
    <offering profile='IBM WebSphere Application Server V9.0' id='com.ibm.websphere.ND.v90' version='9.0.2.20161108_1719' features='core.feature,ejbdeploy,thinclient,embeddablecontainer'/>
    <!-- IBM SDK, Java Technology Edition, Version 8 8.0.3.20 -->
    <offering profile='IBM WebSphere Application Server V9.0' id='com.ibm.java.jdk.v8' version='8.0.3020.20161024_1413' features='com.ibm.sdk.8'/>
  </install>
  <profile id='IBM WebSphere Portal Server V8.5' installLocation='$wasportaldirectories/PortalServer'>
    <data key='user.was.installLocation,com.ibm.websphere.PORTAL.SERVER.v85' value='$wasportaldirectories/AppServer'/>
    <data key='user.wp.wasprofiles.location,com.ibm.websphere.PORTAL.SERVER.v85' value='$wasportaldirectories/AppServer/profiles'/>
    <data key='user.wp.profilename,com.ibm.websphere.PORTAL.SERVER.v85' value='wp_profile'/>
    <data key='user.wp.profilepath,com.ibm.websphere.PORTAL.SERVER.v85' value='$wasportaldirectories/wp_profile'/>
    <data key='user.configengine.binaryLocation,com.ibm.websphere.PORTAL.SERVER.v85' value='$wasportaldirectories/ConfigEngine'/>
    <data key='user.wp.userid,com.ibm.websphere.PORTAL.SERVER.v85' value='$wpsusername'/>
    <data key='user.wp.password,com.ibm.websphere.PORTAL.SERVER.v85' value='$enwpspasswd'/>
    <data key='user.cw.userid,com.ibm.websphere.PORTAL.SERVER.v85' value='$cwusername'/>
    <data key='user.cw.password,com.ibm.websphere.PORTAL.SERVER.v85' value='$encwpasswd'/>
    <data key='user.wp.hostname,com.ibm.websphere.PORTAL.SERVER.v85' value='$HOSTNAME'/>
    <data key='user.wp.cellname,com.ibm.websphere.PORTAL.SERVER.v85' value='$HOSTNAMECell'/>
    <data key='user.wp.nodename,com.ibm.websphere.PORTAL.SERVER.v85' value='$HOSTNAMENode'/>
    <data key='user.wp.custom.contextroot,com.ibm.websphere.PORTAL.SERVER.v85' value='wps'/>
    <data key='user.wp.custom.defaulthome,com.ibm.websphere.PORTAL.SERVER.v85' value='portal'/>
    <data key='user.wp.custom.personalhome,com.ibm.websphere.PORTAL.SERVER.v85' value='myportal'/>
    <data key='user.wp.starting.port,com.ibm.websphere.PORTAL.SERVER.v85' value='10012'/>
    <data key='user.iim.currentlocale,com.ibm.websphere.PORTAL.SERVER.v85' value='en'/>
    <data key='user.wp.base.offering,com.ibm.websphere.PORTAL.SERVER.v85' value='portal.server'/>
  </profile>
  <install>
    <!-- 8.5.0.0-WP-Server-IFPI59896 -->
    <offering profile='IBM WebSphere Portal Server V8.5' id='8.5.0.0-WP-Server-IFPI59896'/>
    <!-- IBM WebSphere Portal Server 8.5.0.0 -->
    <offering profile='IBM WebSphere Portal Server V8.5' id='com.ibm.websphere.PORTAL.SERVER.v85' version='8.5.0.20140424_2155' features='ce.install,portal.binary,portal.profile'/>
  </install>
  <preference name='com.ibm.cic.common.core.preferences.eclipseCache' value='${sharedLocation}'/>
  <preference name='com.ibm.cic.common.core.preferences.connectTimeout' value='30'/>
  <preference name='com.ibm.cic.common.core.preferences.readTimeout' value='45'/>
  <preference name='com.ibm.cic.common.core.preferences.downloadAutoRetryCount' value='0'/>
  <preference name='offering.service.repositories.areUsed' value='false'/>
  <preference name='com.ibm.cic.common.core.preferences.ssl.nonsecureMode' value='false'/>
  <preference name='com.ibm.cic.common.core.preferences.http.disablePreemptiveAuthentication' value='false'/>
  <preference name='http.ntlm.auth.kind' value='NTLM'/>
  <preference name='http.ntlm.auth.enableIntegrated.win32' value='true'/>
  <preference name='com.ibm.cic.common.core.preferences.preserveDownloadedArtifacts' value='true'/>
  <preference name='com.ibm.cic.common.core.preferences.keepFetchedFiles' value='false'/>
  <preference name='PassportAdvantageIsEnabled' value='false'/>
  <preference name='com.ibm.cic.common.core.preferences.searchForUpdates' value='false'/>
  <preference name='com.ibm.cic.agent.ui.displayInternalVersion' value='false'/>
  <preference name='com.ibm.cic.common.sharedUI.showErrorLog' value='true'/>
  <preference name='com.ibm.cic.common.sharedUI.showWarningLog' value='true'/>
  <preference name='com.ibm.cic.common.sharedUI.showNoteLog' value='true'/>
</agent-input>

EOF
fi
echo -e " \033[32m
***** INSTALLING BASE VERSION OF PRODUCTS PLEASE WAIT *****
\033[0m
"
if [ "$b" = "-dry"]
then
 echo "$imclinstalledpath/imcl -acceptLicense input  $responcefilepath/WP90_pt1_server_full_install.xml.xml -log /tmp/portalbase.log -showProgress runs here... $'\n'"
else
 $imclinstalledpath/imcl -acceptLicense input  $responcefilepath/WP90_pt1_server_full_install.xml.xml -log /tmp/portalbase.log -showProgress
fi

echo " ";

echo "Check the portal console url if it is accessible or not: 'https://$HOSTNAME:10039/wps/portal'

Press ANY BUTTON once done... ";
read button;

echo -e "
____ _____ ___ ___
|      |   |   |  |          **
|___   |   |_  |__|            *   
   |   |   |   |             ***      ---- CF13 Upgrade
___|   |   |__ |               *
                             **

"
if [ "$b" = "-dry" ]
then
 echo "CF13 responce file will be created at $responcefilepath/WP90_pt2_CF13_Upgrade.xml";
else
cat << EOF > $responcefilepath/WP90_pt2_CF13_Upgrade.xml

<?xml version="1.0" encoding="UTF-8"?>
<agent-input>
  <variables>
    <variable name='sharedLocation' value='$imsharelocation/IMShared'/>
  </variables>
  <server>
    <repository location='$binariespath/products/WP8500CF13_Server/repository.config'/>
  </server>
  <install modify='false'>
    <offering id='com.ibm.websphere.PORTAL.SERVER.v85' profile='IBM WebSphere Portal Server V8.5' features='ce.install,portal.binary,portal.profile' installFixes='none'/>
  </install>
  <preference name='com.ibm.cic.common.core.preferences.eclipseCache' value='${sharedLocation}'/>
  <preference name='com.ibm.cic.common.core.preferences.connectTimeout' value='30'/>
  <preference name='com.ibm.cic.common.core.preferences.readTimeout' value='45'/>
  <preference name='com.ibm.cic.common.core.preferences.downloadAutoRetryCount' value='0'/>
  <preference name='offering.service.repositories.areUsed' value='true'/>
  <preference name='com.ibm.cic.common.core.preferences.ssl.nonsecureMode' value='false'/>
  <preference name='com.ibm.cic.common.core.preferences.http.disablePreemptiveAuthentication' value='false'/>
  <preference name='http.ntlm.auth.kind' value='NTLM'/>
  <preference name='http.ntlm.auth.enableIntegrated.win32' value='true'/>
  <preference name='com.ibm.cic.common.core.preferences.preserveDownloadedArtifacts' value='true'/>
  <preference name='com.ibm.cic.common.core.preferences.keepFetchedFiles' value='false'/>
  <preference name='PassportAdvantageIsEnabled' value='false'/>
  <preference name='com.ibm.cic.common.core.preferences.searchForUpdates' value='false'/>
  <preference name='com.ibm.cic.agent.ui.displayInternalVersion' value='false'/>
  <preference name='com.ibm.cic.common.sharedUI.showErrorLog' value='true'/>
  <preference name='com.ibm.cic.common.sharedUI.showWarningLog' value='true'/>
  <preference name='com.ibm.cic.common.sharedUI.showNoteLog' value='true'/>
</agent-input>

EOF
fi
if [ "$b" = "-dry" ]
then 
 echo " Application will be stopped using below commands
$wasportaldirectories/wp_profile/bin/stopServer WebSphere_Portal -username $wpsusername -password $enwpspasswd
$wasportaldirectories/AppServer/profiles/cw_profile/bin/stopServer server1 -username $cwusername -password $encwpasswd
"
else
 read -p "To Upgrade to CF13 all the application servers related to Portal needs to be stopped.`echo $'\n'$'\n'If you choose Y for the below option, script will use 'ps -ef | grep java | xargs kill' to kill all the running java process in the system to save time`. `echo $'\n'If you choose N the script will stop the java process of wp_profile and cw_profile using stop server command` `echo $'\n'$'\n'Enter Y/N: `" answer;
 echo " ";
 if [ $answer == Y ] || [ $answer == y ];
 then
    ps -ef | grep java | xargs kill;

 else
    echo "Please wait for the processess to get stopped";
    $wasportaldirectories/wp_profile/bin/stopServer WebSphere_Portal -username $wpsusername -password $enwpspasswd;
    $wasportaldirectories/AppServer/profiles/cw_profile/bin/stopServer server1 -username $cwusername -password $encwpasswd;
 fi
 echo " ";
fi

echo -e " \033[32m 
***** CF13 Upgrade is being done, please wait *****
\033[0m
"

if [ "$b" = "-dry" ]
then 
 echo "$imclinstalledpath/imcl -acceptLicense input $responcefilepath/WP90_pt2_CF13_Upgrade.xml  -log /tmp/wcmdf.log -showProgress runs here..."
else
 $imclinstalledpath/imcl -acceptLicense input $responcefilepath/WP90_pt2_CF13_Upgrade.xml  -log /tmp/wcmdf.log -showProgress
 echo " ";
fi
echo -e " \033[32m
***** ApplyCF13.sh script is being run - Will take long time to run so patience is appreciated *****
\033[0m
"

if [ "$b" = "-dry" ]
then 
 echo "$wasportaldirectories/wp_profile/PortalServer/bin/applyCF.sh -DWasPassword=$wpsusername -DPortalAdminPwd=$enwpspasswd runs here..."
else
 $wasportaldirectories/wp_profile/PortalServer/bin/applyCF.sh -DWasPassword=$wpsusername -DPortalAdminPwd=$enwpspasswd
fi

echo " ";

echo "
____ _____ ___ ___
|      |   |   |  |           +*
|___   |   |_  |__|          * *
   |   |   |   |            ****      ---- V9 Upgrade of Portal
___|   |   |__ |               *
                              

"
if [ "$b" = "-dry" ]
then
 echo "Version 9 upgrade responce file will be created at $responcefilepath/WP90_pt3_version9_install.xml";
else
cat << EOF > $responcefilepath/WP90_pt3_version9_install.xml

<?xml version='1.0' encoding='UTF-8'?>
<agent-input>
  <variables>
    <variable name='sharedLocation' value='$imsharelocation/IMShared'/>
  </variables>
  <server>
    <repository location='$binariespath/products/WP90_Portal/repository.config'/>
  </server>
  <profile id='IBM WebSphere Portal Server V8.5' installLocation='$wasportaldirectories/PortalServer'>
    <!-- Specify your current WebSphere Application Server administrative user password -->
    <data key='user.p9.was.password,com.ibm.websphere.PORTAL.SERVER.v90' value='$enwpspasswd'/>
    <!-- Specify your current Portal administrative user password -->
    <data key='user.p9.wp.password,com.ibm.websphere.PORTAL.SERVER.v90' value='$enwpspasswd'/>
  </profile>
  <install>
    <!-- IBM WebSphere Portal Server 9.0.0.0 -->
    <offering profile='IBM WebSphere Portal Server V8.5' id='com.ibm.websphere.PORTAL.SERVER.v90' version='9.0.0.20161208_1437' features='portal9.upsell'/>
  </install>
  <preference name='com.ibm.cic.common.core.preferences.eclipseCache' value='${sharedLocation}'/>
  <preference name='offering.service.repositories.areUsed' value='false'/>
  <preference name='com.ibm.cic.common.core.preferences.searchForUpdates' value='false'/>
</agent-input>

EOF
fi
if [ "$b" = "-dry" ]
then
 echo "ps -ef | grep java | xargs kill; or $wasportaldirectories/wp_profile/bin/stopServer WebSphere_Portal -username $wpsusername -password $enwpspasswd, $wasportaldirectories/AppServer/profiles/cw_profile/bin/stopServer server1 -username $cwusername -password $encwpasswd commands run here..."
else
 read -p "To Upgrade to CF13 all the application servers related to Portal needs to be stopped.`echo $'\n'$'\n'If you choose Y for the below option, script will use 'ps -ef | grep java | xargs kill' to kill all the running java process in the system to save time`. `echo $'\n'If you choose N the script will stop the java process of wp_profile and cw_profile using stop server command` `echo $'\n'$'\n'Enter Y/N: `" answer;
 echo " ";
 if [ $answer == Y ] || [ $answer == y ];
 then
    ps -ef | grep java | xargs kill;

 else
    echo "Please wait for the processess to get stopped";
    $wasportaldirectories/wp_profile/bin/stopServer WebSphere_Portal -username $wpsusername -password $enwpspasswd;
    $wasportaldirectories/AppServer/profiles/cw_profile/bin/stopServer server1 -username $cwusername -password $encwpasswd;
 fi
 echo " ";
fi
echo -e " \033[32m
***** Portal is being upgraded to version9, Please wait ******
\033[0m"

if [ "$b" = "-dry" ]
then
 echo "$imclinstalledpath/imcl -acceptLicense input $responcefilepath/WP90_pt3_version9_install.xml -log /tmp/wcmdfupgrade.log -showProgress runs here..."
else
 $imclinstalledpath/imcl -acceptLicense input $responcefilepath/WP90_pt3_version9_install.xml -log /tmp/wcmdfupgrade.log -showProgress
 echo " ";
fi

echo -e " \033[32m
***** Version9 features are being applied to the available profiles ******
\033[0m"

if [ "$b" = "-dry" ]
then
 echo "$wasportaldirectories/wp_profile/ConfigEngine.sh enable-v9-features -DWasPassword=$wpsusername -DPortalAdminPwd=$enwpspasswd runs here..."
else
 $wasportaldirectories/wp_profile/ConfigEngine.sh enable-v9-features -DWasPassword=$wpsusername -DPortalAdminPwd=$enwpspasswd
fi

echo "
____ _____ ___ ___
|      |   |   |  |         ****
|___   |   |_  |__|         * 
   |   |   |   |            ****     ----  DB Migration to DB2
___|   |   |__ |                *
                            ****

"

read -p "Enter the DB2 Server hostname or IP addres: " dbhost;
echo " ";

read -p "Enter the Database name for migration: " dbname;
echo " ";

read -p "Enter the port for the database: " dbport;
echo " ";

#read -p "Enter the database username: " dbuser;
#echo " ";

#read -p "Enter the database user password: " -s dbpasswd;
#echo " ";
createdb2database()
{
if [ "$b" = "-dry" ]
then
 echo "Script for DB creation will be created at $responcefilepath/createdb2database.sh"
else
cat << EOF > $responcefilepath/createdb2database.sh

db2set DB2COMM=TCPIP
db2set DB2_EVALUNCOMMITTED=YES
db2set DB2_INLIST_TO_NLJN=YES
db2 "UPDATE DBM CFG USING sheapthres 0"

	
db2 "CREATE DB $dbname using codeset UTF-8 territory us PAGESIZE 8192"
db2 "UPDATE DB CFG FOR $dbname USING locktimeout 30"

db2 "CONNECT TO $dbname USER $dbuser USING $dbuserpasswd"
db2 "CREATE BUFFERPOOL ICMLSFREQBP4 SIZE 1000 AUTOMATIC PAGESIZE 4K"
db2 "CREATE BUFFERPOOL ICMLSVOLATILEBP4 SIZE 16000 AUTOMATIC PAGESIZE 4K"
db2 "CREATE BUFFERPOOL ICMLSMAINBP32 SIZE 16000 AUTOMATIC PAGESIZE 32K"
db2 "CREATE BUFFERPOOL CMBMAIN4 SIZE 1000 AUTOMATIC PAGESIZE 4K"
db2 "CREATE REGULAR TABLESPACE ICMLFQ32 PAGESIZE 32K BUFFERPOOL ICMLSMAINBP32"
db2 "CREATE REGULAR TABLESPACE ICMLNF32 PAGESIZE 32K BUFFERPOOL ICMLSMAINBP32"
db2 "CREATE REGULAR TABLESPACE ICMVFQ04 PAGESIZE 4K BUFFERPOOL ICMLSVOLATILEBP4"
db2 "CREATE REGULAR TABLESPACE ICMSFQ04 PAGESIZE 4K BUFFERPOOL ICMLSFREQBP4"
db2 "CREATE REGULAR TABLESPACE CMBINV04 PAGESIZE 4K BUFFERPOOL CMBMAIN4"
db2 "CREATE SYSTEM TEMPORARY TABLESPACE ICMLSSYSTSPACE32 PAGESIZE 32K BUFFERPOOL ICMLSMAINBP32"
db2 "CREATE SYSTEM TEMPORARY TABLESPACE ICMLSSYSTSPACE4 PAGESIZE 4K BUFFERPOOL ICMLSVOLATILEBP4"
db2 "CREATE USER TEMPORARY TABLESPACE ICMLSUSRTSPACE4 PAGESIZE 4K BUFFERPOOL ICMLSVOLATILEBP4"
db2 "DISCONNECT $dbname"
db2 "TERMINATE"
db2 "UPDATE DB CFG FOR $dbname USING logfilsiz 16000"
db2 "UPDATE DB CFG FOR $dbname USING logprimary 20"
db2 "UPDATE DB CFG FOR $dbname USING logsecond 50"
db2 "UPDATE DB CFG FOR $dbname USING logbufsz 500"
db2 "UPDATE DB CFG FOR $dbname USING DFT_QUERYOPT 5"

EOF
chmod 777 $responcefilepath/createdb2database.sh;
fi
}
read -p "Choose Y If you are authorised to access the DB server using the DB2 instance admin id or a user with privilages to create DB and grant certail privilages. Choosing Y will also need you to copy the ssh key into the DB2 server for the script to automatically transfer the create DB script and setup DB script for creating and preparing the $dbname. `echo "$'\n' Choose N if you are not authorised to access the DB server or dont want to add the ssh key for passwordless access by the script into the DB server"`" answer;
echo " ";
if [ $answer == Y ] || [ $answer == y ];
then

   read -p "Enter the DB2 Instance or privilaged username (Default db2inst1): " db2inst1;
   export db2inst1=`echo "${db2inst1:-db2inst1}"`
   echo " ";
   read -p "Enter the DB2 Instance or privilages user password (Default db2inst1): " -s db2inst1passwd;
   export db2inst1passwd=`echo "${db2inst1passwd:-db2inst1}"`
   echo " ";
   read -p "Choose Y If you want to use the db2 instance id for creating the portal database, else choose N. `echo $'\n'Enter Y/N: `" answer;
   if [ $answer == Y ] || [ $answer == y ];
   then
    dbuser=$db2inst1;
    dbuserpasswd=$db2inst1passwd;
   else
    read -p "Enter the dedicated dbuser name for the database $dbname: " dbuser;
    read -p "Enter the password for $dbuser: " dbuserpasswd;
   fi
   createdb2database $dbname $dbuser $dbuserpasswd
   echo " ";
   if [ $USER != root ]
   then
    echo "Generating the SSH Key for passwordless access to the DB2 server $dbhost. If the key already exists or if the key was generated successfully, copy the contents of /home/$USER/.ssh/id-rsa.pub in to /home/$db2inst1/.ssh/authorised_keys file of the DB2 server. Create the authorised keys file if it does not exist."
    if [ "$b" = "-dry" ]
    then
     echo "ssh-keygen -f /home/$USER/.ssh/id-rsa runs here..."
    else
     ssh-keygen -f /home/$USER/.ssh/id-rsa
    fi
   else
    echo "Generating the SSH Key for passwordless access to the DB2 server $dbhost. If the key already exists or if the key was generated successfully, copy the contents of ~/.ssh/id-rsa.pub in to /home/$db2inst1/.ssh/authorised_keys file of the DB2 server. Create the authorised keys file if it does not exist."
    if [ "$b" = "-dry" ]
    then
     echo "ssh-keygen -f ~/.ssh/id-rsa runs here..."
    else
     ssh-keygen -f ~/.ssh/id-rsa
    fi
   fi
   echo " ";
   read -p "The DB2 Create database script is generated at $responcefilepath/createdb2database.sh. Please verify the values and press enter once done. " button;
   if [ "$b" = "-dry" ]
   then
    echo "scp $responcefilepath/createdb2database.sh  $db2inst1@$dbhost:/home/$db2inst1/
   ssh $db2inst1@$dbhost "cd /home/$db2inst1 && chmod 777 $responcefilepath/createdb2database.sh && /home/$db2inst1/createdb2database.sh runs here...""
   else
    scp $responcefilepath/createdb2database.sh  $db2inst1@$dbhost:/home/$db2inst1/
    ssh $db2inst1@$dbhost "cd /home/$db2inst1 && chmod 777 $responcefilepath/createdb2database.sh && /home/$db2inst1/createdb2database.sh"
   fi
else
   
   echo "Enter the details for generating the script for creating the DB and setup the DB
   "
   read -p "Enter the dedicated dbuser name for the database $dbname: " dbuser;
   echo " ";
   read -p "Enter the password for $dbuser: " dbuserpasswd;
   echo " ";
   createdb2database $dbname $dbuser $dbuserpasswd
   echo "Copy the script $responcefilepath/createdb2database.sh into the DB2 server $dbhost and execute it to create the $dbname db"
   echo " "
   read -p  "Press ANY BUTTON once done..." button;

fi

