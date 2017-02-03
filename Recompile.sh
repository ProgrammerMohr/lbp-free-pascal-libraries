#!/bin/bash

# *************************************************************************
# * This script will recompile all Lloyd's Free Pascal programs.  In order
# * To work properly, each directory which needs to be compiled should be 
# * listed in the variable below.  Order is important!  For example, since 
# * much of the other code depends on packages in utils, utils should be
# * the first directory listed.
# *************************************************************************

SourceDirs='
   utils
   utils/linux
   utils/net
   utils/tests
   ldap
   sql/mysqllib
   sql/mysqllib4
   sql
   homeschool
   lloyd/amey_photo_transfer
   lloyd/compiler
   lloyd/home_firewall
   lloyd/isis
   lloyd/xbmc_remote
   netserv/apps/XvncStarter
   netserv/apps/arp-scan
   netserv/apps/bandwidth-db
   netserv/apps/bash-login-shell
   netserv/apps/cd-devel
   netserv/apps/cisco_config
   netserv/apps/cvs-move-root
   netserv/apps/dns-add
   netserv/apps/download-db
   netserv/apps/ipdb-copy-rights
   netserv/apps/openvpn-doorkeeper
   netserv/apps/osc-process-bpb-list
   netserv/apps/proxy-cgi
   netserv/apps/proxy-url-rewrite
   netserv/apps/proxy-user-list
   netserv/apps/rancid-looking-glass
   netserv/apps/ssh-url-handler
   netserv/apps/string_to_unix_time
   netserv/apps/tivoli-backup
   netserv/apps/xcolor-to-apple
   netserv/dhcp
   netserv/dns/compare
   netserv/infoblox
   netserv/infoblox/import
   netserv/infoblox/report
   netserv/ipdb2
   netserv/ipdb2/exports
   netserv/ipdb2/exports/infoblox_import
   netserv/ipdb2/exports/isc_dhcp_config_out
   netserv/ipdb2/imports
   netserv/ipdb2/imports/arp-last-seen
   netserv/ipdb2/imports/prune_admin_rights
   netserv/ipdb2/moves
   netserv/ipdb2/reports
   netserv/ipdb2/reports/admins
   netserv/ipdb2/reports/billing
   netserv/ipdb2/reports/inventory
   netserv/ipdbsync
   netserv/ipdbsync/reports
   netserv/parature
   secserv
   secserv/authbridge
   timothy/launch_control
'


# *************************************************************************
# Possible base Free Pascal code directories.  If there are multiple matches, 
# only the last one will be used.
# *************************************************************************

AllowedBaseDirs='
   programming/code/pascal
   programming/pascal
   /opt/programming/pascal
'


# *************************************************************************
# * MoveToBaseDir() - cd to the base free pascal code directory
# *************************************************************************

MoveToBaseDir() {
   local TESTDIR
   local HomeDir
   cd ~
   HomeDir=`pwd`
   for TESTDIR in ${AllowedBaseDirs}; do
      if [[ -d ${TESTDIR} ]]; then
         cd ${TESTDIR}
      fi
   done
   
   if [[ ${HomeDir} == `pwd` ]]; then
      echo >&2
      echo >&2
      echo >&2
      echo 'Unable to find the base Free Pascal directory!  Exiting.' >&2
      echo >&2
      echo >&2
      exit -1
   fi 
}


# *************************************************************************
# * CompileDir() - Compile all the pascal code in the passed directory
# *************************************************************************

CompileDir() {
   if [[ ! -d $1 ]]; then
      echo >&2
      echo >&2
      echo '********************************************************' >&2
      echo "* The directory ${SOURCEDIR} does not exist!  Exiting..." >&2
      echo '********************************************************' >&2
      echo >&2
      exit -1
   fi
   
   echo
   echo
   echo '********************************************************'
   echo "* Compiling code in ${SOURCEDIR}"
   echo '********************************************************'
   echo
 
   cd $1
   rm -f *.ppu *.o
   for FILE in *.pas; do
      fpc ${FILE}
   done;
   cd - >/dev/null
}


# *************************************************************************
# * main()
# *************************************************************************

MoveToBaseDir
for SOURCEDIR in ${SourceDirs}; do
   CompileDir ${SOURCEDIR}   
done

echo
echo
echo '********************************************************'
echo "* Done"
echo '********************************************************'
echo
