#!/bin/zsh

function terminate_now(){
   pkill -P $$
}

pseudo_progress(){
while :
do
   localTotalBytes=$(du -d0 -A /tmp/RSYNC_DOWNLOADER | awk '{print $1}')
   tmp_progress=$(echo -n "$1 $localTotalBytes" | awk "{print int((($localTotalBytes+$1)/$1*100-100)/2)}")

   if [ $tmp_progress -ge 99 ];then
      break
   fi
   clear
   # echo -e "localTotalBytes=$localTotalBytes\ntargetTotalBytes=$1\nprogress=$tmp_progress"
   echo $tmp_progress%
   sleep 1
done
}

trap terminate_now INT

if [[ -z "$1"  ]] || [[ -z "$2" ]] || [[ -z "$3" ]] || [[ -z "$4" ]] ;then
   echo "Usage: rsync-downloader.sh root 1.2.3.4 /server/public /home/user/downloads"
   exit 1
fi

if [ -d $4 ];then
   if [ "$(du -d0 $4 | awk '{print $1}')" -ne 0 ];then
      echo "Destination folder must be empty"
      exit
   fi
fi

mkdir -p $4
mkdir -p /tmp/RSYNC_DOWNLOADER

ssh $1@$2 whoami &> /dev/null
if [[ $? -ne 0 ]];then
   echo "Could not connect"
   exit 1
fi

ssh $1@$2 ls $3 &> /dev/null
if [[ $? -ne 0 ]];then
   echo "No such folder"
   exit 2
fi

echo "Are you sure want to download the following folder?"
ssh $1@$2 du -d0 -h $3

result=$(ssh $1@$2 du -d0 $3)
targetTotalBytes=$(echo $result | awk '{print $1}')

echo -e "\nContinue? [y/n]"
read download_now

if [[ $download_now == "y" ]];then
   echo "Downloading..."
   pseudo_progress $targetTotalBytes $4 &
   rsync -a -T /tmp/RSYNC_DOWNLOADER $1@$2:$3 $4 &> /dev/null
   terminate_now
else
   echo "Abort"
fi