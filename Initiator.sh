#! /bin/bash

#############################################################
#     _____ __________________          ___            	    #
#    / ___// ____/_  __/ ____/___  ____/ (_)___  ____ _     #
#    \__ \/ /     / / / /   / __ \/ __  / / __ \/ __ `/     #
#   ___/ / /___  / / / /___/ /_/ / /_/ / / / / / /_/ /      #
#  /____/\____/ /_/  \____/\____/\__,_/_/_/ /_/\__, /       # 
#                                             /____/        #  
#############################################################

#############################################################
## Create by Simon Carlson-Thies on 4/21/22
## Copyright © 2022 Simon Carlson-Thies All rights reserved.
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.
#############################################################

OSVersionTarget="$4"
OSInstallerFilePath="$5"
desiredOSBundleVersion="$6"
CFBundleVersionDesired=$(echo -n "$desiredOSBundleVersion" | /usr/bin/xargs | /usr/bin/sed -e 's/\.//g')

## Format: "YYYY-MM-DD HH:MM:SS"
startTime=$(date '+%Y-%m-%d %h:%m:%s')

if [[ -e "$OSInstallerFilePath" ]] && [[ $(/usr/bin/defaults read "${OSInstallerFilePath}/Contents/Info.plist" CFBundleShortVersionString | /usr/bin/xargs) == "$desiredOSBundleVersion" ]]
then
    echo "Installer already downloaded: ${OSInstallerFilePath}."
    exit 0
elif [[ -e "$OSInstallerFilePath" ]] && [[ $(/usr/bin/defaults read "${OSInstallerFilePath}/Contents/Info.plist" CFBundleVersion | /usr/bin/xargs) -lt $CFBundleVersionDesired ]]
then
    echo "Removing incorrect installer bundle."
    rm -rf "${OSInstallerFilePath}"
fi

## Keep machine from sleeping
if [[ ! -e "/usr/local/caffinePID" ]]
then
    nohup /usr/bin/caffeinate -i &
    echo $! > /usr/local/caffinePID
else
    if [[ -z $(ps -A | /usr/bin/grep "$(cat "/usr/local/caffinePID")") ]]
    then
        nohup /usr/bin/caffeinate -i &
        echo $! > /usr/local/caffinePID
    fi
fi

## Start the OS download
if [[ -z $(ps -A | /usr/bin/grep "/usr/sbin/softwareupdate --fetch-full-installer --full-installer-version ${OSVersionTarget}" | /usr/bin/grep -v "grep") ]] && [[ -z $(cat "/usr/local/osDownloadProgress" | /usr/bin/grep "Install finished successfully") ]]
then

    if [[ ! -e "/usr/local/OSDownloadStatus" ]]
    then
        echo "IN PROGRESS:${startTime}" > /usr/local/OSDownloadStatus
    fi
    
    /usr/bin/notifyutil -p "OS_Upgrade_Download_Started"
    nohup /usr/sbin/softwareupdate --fetch-full-installer --full-installer-version "$OSVersionTarget" >> /usr/local/osDownloadProgress &
else
    lastLine=$(cat "/usr/local/osDownloadProgress" | /usr/bin/tail -n 2)
    echo "Current Status: ${lastLine}"
fi

exit 0
