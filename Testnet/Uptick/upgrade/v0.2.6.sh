#!/bin/bash
GREEN_COLOR='\033[0;32m'
RED_COLOR='\033[0;31m'
NO_COLOR='\033[0m'
BLOCK=2219700
VERSION=v0.2.6
echo -e "$GREEN_COLOR YOUR NODE WILL BE UPDATED TO VERSION: $VERSION ON BLOCK NUMBER: $BLOCK $NO_COLOR\n"
for((;;)); do
        height=$(uptickd status |& jq -r ."SyncInfo"."latest_block_height")
        if ((height>=$BLOCK)); then

                source $HOME/.bash_profile
                sudo systemctl stop uptickd
                cd $HOME
                sudo mv uptickd $(which uptickd)
                rm -rf $VERSION.tar.gz uptick-linux-amd64-$VERSION
                sudo systemctl restart uptickd && journalctl -fu uptickd -o cat

                for (( timer=60; timer>0; timer-- )); do
                        printf "* second restart after sleep for ${RED_COLOR}%02d${NO_COLOR} sec\r" $timer
                        sleep 1
                done
                height=$(uptickd status |& jq -r ."SyncInfo"."latest_block_height")
                if ((height>$BLOCK)); then
                        echo -e "$GREEN_COLOR YOUR NODE WAS SUCCESFULLY UPDATED TO VERSION: $VERSION $NO_COLOR\n"
                fi
                uptickd version --long | head
                break
        else
                echo -e "${GREEN_COLOR}$height${NO_COLOR} ($(( BLOCK - height  )) blocks left)"
        fi
        sleep 5
done
