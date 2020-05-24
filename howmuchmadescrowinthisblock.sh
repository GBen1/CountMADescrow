#!/bin/bash


yel='\e[1;33m'
neutre='\e[0;m'
gr='\e[1;32m'
red='\e[1;31m'
bl='\e[1;36m'
flred='\e[1;41m'


cd

clear

echo "_________________________________________________________"
echo ""
echo ":: Updating repos, packages and installing dependencies.."
echo ""

#apt-get install sudo -y
#sudo apt update -y && sudo apt -y upgrade
#sudo apt install -y netcat-openbsd python git unzip pv jq dnsutils bc python-pip python-qrcode
#sudo pip install qrcode[pil]

apt install bc <<< y

apt-get install sudo -y

sudo apt-get -y install netcat-openbsd <<< y

sudo apt-get update && sudo apt-get upgrade <<< y

sudo apt-get install python git unzip pv jq <<< y

sudo apt-get install python git unzip pv jq dnsutils <<< y

sudo apt install bc <<< y

sudo apt install python-pip <<< y

sudo pip install qrcode[pil] <<< y

sudo apt install python-qrcode <<< y

sudo apt install python3-qrcode <<< y


clear

echo "_________________________________________________________"
echo ""
echo ":: Installing Partyman staking utility.."
echo ""

cd ~ && git clone https://github.com/dasource/partyman

cd && cd partyman

yes | ./partyman install

clear

yes | ./partyman restart now

checkpartyman=$(./partyman status | grep YES | wc -c)

if [[ "$checkpartyman" -lt 1 ]] ; then
cd
cd particlcore
./particl-cli stop
echo -e "${flred}ERROR: PARTYMAN INSTALL/RESTART FAILED${neutre}" 
exit
fi


while [ "$checkinit" != "35" ]
do
clear
./partyman stakingnode init
cd && cd particlcore 
rewardaddress=$(./particl-cli getnewaddress) 
checkinit=$(echo "$rewardaddress" | wc -c)  
cd && cd partyman
done

cd && cd partyman

echo "_________________________________________________________"
echo ""
echo ":: Updating Partyman to latest version.."
echo ""

git pull

clear

yes | ./partyman update

clear

cd && cd particlcore
checksynced=$(./particl-cli getblockcount)
if [[ "$checksynced" -lt 698663 ]] ; then
echo -e "${flred}ERROR: THE BLOCKCHAIN IS NOT FULLY SYNCHRONIZED ${neutre}" 
exit
fi



blockdisplay=0
while ((blockdisplay < 1))
do
clear
echo -e "${yel}Enter the number of the block you want to display:${neutre}" && read blockdisplay
blockdisplay=$(echo $blockdisplay | cut -d "." -f 1 | cut -d "," -f 1 | tr -d [a-zA-Z]| sed -n '/^[[:digit:]]*$/p' )
done

cd
cd particlcore

rm ../CountMADescrow/lastblocksearch.txt


blockhash=$(./particl-cli getblockstats $blockdisplay | grep blockhash | sed 's/.* //' | sed 's/"//' | sed 's/"//' | sed 's/,//')



txcount=$(./particl-cli getblock $blockhash | cut -c5- | grep "^\"" | sed 's/"//' | sed 's/"//' | sed 's/,//' | wc -l)
currenttx=1
txcount=$(($txcount + 1))

# for each tx in this block do:
while [ "$txcount" -gt "$currenttx" ]
do
txid=$(./particl-cli getblock $blockhash | cut -c5- | grep "^\"" | sed 's/"//' | sed 's/"//' | sed 's/,//' | sed -n "$currenttx p")





rawtx=$(./particl-cli getrawtransaction $txid)

./particl-cli decoderawtransaction $rawtx >> ../CountMADescrow/lastblocksearch.txt



currenttx=$(($currenttx + 1))
done
clear
 numad=$(cat ../CountMADescrow/lastblocksearch.txt | grep -A 10 blind | cut -c12- | grep -E ^R | sed -n '1~2p' | sed 's/"//' | wc -l)
 madlist=$(cat ../CountMADescrow/lastblocksearch.txt | grep -A 10 blind | cut -c12- | grep -E ^R | sed -n '1~2p' | sed 's/"//')
 
echo -e "${yel}$numad MADESCROWS CREATED IN THE BLOCK $blockdisplay: ${neutre}"
echo ""
echo -e "${gr}$madlist${neutre}"
echo ""
rm ../CountMADescrow/lastblocksearch.txt
