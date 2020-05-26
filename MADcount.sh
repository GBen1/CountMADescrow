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
cd
cd particlcore

# The blockchain has to be fully synchronized to count the madescrows from the block $currentblock to the lattest one, 
# if someone launch the script when the script is synchronized between 698663 and the latest block (not included) it won' t work.
curl_cmd="timeout 7 curl -4 -s -L -A i ../partyman/$PARTYMAN_VERSION"
highestblock=$($curl_cmd https://explorer.particl.io/particl-insight-api/sync 2>/dev/null | jq -r .blockChainHeight)
checksynced=$(./particl-cli getblockcount)
if [[ "$checksynced" -lt "$highestblock" ]] ; then
echo -e "${flred}ERROR: THE BLOCKCHAIN IS NOT FULLY SYNCHRONIZED ${neutre}" 
echo -e "${flred}TRY AGAIN IN FEW MINUTES ${neutre}"
exit
fi

#delete this file to not keep the informations of the latest block scanned if this script has already been used
rm ../CountMADescrow/lastblocksearch.txt 2>/dev/null

#what is the highest block synchronized on this node ?
latestblock=$(./particl-cli getblockcount) 

currentblock=0
while ((currentblock < 506468))
do
clear
#It s not useful t start counting before the block 506468 for the reason explained below
echo -e "${red}The first Private MADescrow has been created during the block 506469 we are at the block $latestblock ${neutre}"
echo -e "${yel}From which block do you want to count the Private MADescrow creations ?${neutre}" && read currentblock
currentblock=$(echo $currentblock | cut -d "." -f 1 | cut -d "," -f 1 | tr -d [a-zA-Z]| sed -n '/^[[:digit:]]*$/p' )
beginning=$(echo $currentblock | cut -d "." -f 1 | cut -d "," -f 1 | tr -d [a-zA-Z]| sed -n '/^[[:digit:]]*$/p' )
done

#initialize the counter
madtot=0
#for each block do...
while [ "$latestblock" -gt "$currentblock" ]
do 
madblock=0

#select the blockhash of this block
blockhash=$(./particl-cli getblockstats $currentblock | grep blockhash | sed 's/.* //' | sed 's/"//' | sed 's/"//' | sed 's/,//')

#How much tx in this block ?
txcount=$(./particl-cli getblock $blockhash | cut -c5- | grep "^\"" | sed 's/"//' | sed 's/"//' | sed 's/,//' | wc -l)

currenttx=1
txcount=$(($txcount + 1))

# for each tx in this block do:
while [ "$txcount" -gt "$currenttx" ]
do


#select the current tx in the blockhash
txid=$(./particl-cli getblock $blockhash | cut -c5- | grep "^\"" | sed 's/"//' | sed 's/"//' | sed 's/,//' | sed -n "$currenttx p")

#get rawtransaction of the current tx
rawtx=$(./particl-cli getrawtransaction $txid)

#decode raw tx and print the current tx in a txt file (and add it to the other tx if it s not the first loop of this block)
./particl-cli decoderawtransaction $rawtx >> ../CountMADescrow/lastblocksearch.txt 2>/dev/null


currenttx=$(($currenttx + 1))
done

# If there are 2 blind tx which deposit an address beginning by R during the same block there is a Madescrow created in this block. 
# Need to be improved but pretty accurate for the moment

numad=$(cat ../CountMADescrow/lastblocksearch.txt | grep -A 10 blind | cut -c12- | grep -E ^R | sed -n '1~2p' | sed 's/"//' | wc -l)

#increase the madescrow counter if there are madescrows in this block
madtot=$(printf '%.3f\n' "$(echo "$madtot" "+" "$numad" | bc -l )")
madtot=$(echo "$madtot" | cut -d "." -f 1 | cut -d "," -f 1)


echo -e "${yel}$numad${neutre} ${gr}PRIVATE MADESCROW CREATED IN THE BLOCK $currentblock${neutre}"
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROWS CREATED SINCE THE BLOCK $beginning${neutre}"
echo ""



#delete the txt file to have a new one empty for the next block
rm ../CountMADescrow/lastblocksearch.txt  2>/dev/null

currentblock=$(($currentblock + 1)) 
done

