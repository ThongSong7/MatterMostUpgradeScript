#!/bin/bash
# Version: 2023-04-24
# Mattermost documentation: https://docs.mattermost.com/upgrade/upgrading-mattermost-server.html
# Mattermost download: https://mattermost.com/download/

# Variables
currentVersion=$(curl -v --silent https://mattermost.com/download/ 2>&1 | grep 'release-info' -A 2 | grep -Eo '[[:digit:]]+.[[:digit:]]+.[[:digit:]]+')
echo 'Current version is:' $currentVersion
downloadLink="https://releases.mattermost.com/${currentVersion}/mattermost-team-${currentVersion}-linux-amd64.tar.gz"
echo 'Download link is:' $downloadLink
fileName=${downloadLink##*/}
echo 'File name is:' $fileName

# Continue?
read -p 'Do you want to continue (y/n)?' decision

# Start
if [ "$decision" = "y" ]; then
    echo 'Moving to /tmp'
    cd /tmp

    echo 'Downloading latest version'
    wget $downloadLink

    echo 'Extracting files'
    tar -xf mattermost*.gz --transform='s,^[^/]\+,\0-upgrade,'

    echo 'Stopping mattermost service'
    sudo systemctl stop mattermost

    echo 'Backing up current files'
    cd /opt
    cp -ra mattermost/ mattermost-back-$(date +'%F-%H-%M')/

    echo 'Removing all files except special directories from within the current mattermost directory'
    find mattermost/ mattermost/client/ -mindepth 1 -maxdepth 1 \! \( -type d \( -path mattermost/client -o -path mattermost/client/plugins -o -path mattermost/config -o -path mattermost/logs -o -path mattermost/plugins -o -path mattermost/data \) -prune \) | sort | sudo xargs rm -r

    echo 'Copying the new files to your install directory and remove the temporary files'
    cp -an /tmp/mattermost-upgrade/. mattermost/

    echo 'Changing ownership of new files and folders'
    chown -hR mattermost:mattermost mattermost/

    echo 'Starting mattermost service'
    sudo systemctl start mattermost

    echo 'Removing downloaded file'
    rm -r /tmp/mattermost-upgrade/
    rm /tmp/$fileName

    echo 'Finished.'
    exit 0
else
    echo 'Exiting.'
    exit 1
fi
