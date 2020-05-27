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
curl_cmd="timeout 7 curl -4 -s -L -A i ../partyman/$PARTYMAN_VERSION"
highestblock=$($curl_cmd https://explorer.particl.io/particl-insight-api/sync 2>/dev/null | jq -r .blockChainHeight)
checksynced=$(./particl-cli getblockcount)
if [[ "$checksynced" -lt "$highestblock" ]] ; then
echo -e "${flred}ERROR: THE BLOCKCHAIN IS NOT FULLY SYNCHRONIZED ${neutre}" 
echo -e "${flred}TRY AGAIN IN FEW MINUTES ${neutre}"
exit
fi

#delete this file to not keep the informations of the latest txid scanned if this script has already been used
rm ../CountMADescrow/lasttxidsearch.txt 2>/dev/null

#what is the highest block synchronized on this node ?
latestblock=$(./particl-cli getblockcount) 

currentblock=0
while ((currentblock < 1))
do
clear
echo -e "${yel}Enter the block number in which one you want to know how much madescrows there are:${neutre}" && read currentblock
blockdisplay=$(echo $blockdisplay | cut -d "." -f 1 | cut -d "," -f 1 | tr -d [a-zA-Z]| sed -n '/^[[:digit:]]*$/p' )
done


#reinititialize madblock
madblock=0

#select the blockhash of this block
blockhash=$(./particl-cli getblockstats $currentblock | grep blockhash | sed 's/.* //' | sed 's/"//' | sed 's/"//' | sed 's/,//')

#How much txid in this block ?
txcount=$(./particl-cli getblock $blockhash | cut -c5- | grep "^\"" | sed 's/"//' | sed 's/"//' | sed 's/,//' | wc -l)

currenttx=1
txcount=$(($txcount + 1))

# for each txid in this block do:
while [ "$txcount" -gt "$currenttx" ]
do

#reinitialize madtxid
madtxid=0


#select the current tx in the blockhash
txid=$(./particl-cli getblock $blockhash | cut -c5- | grep "^\"" | sed 's/"//' | sed 's/"//' | sed 's/,//' | sed -n "$currenttx p")

#get rawtransaction of the current tx
rawtx=$(./particl-cli getrawtransaction $txid)

#decode raw tx and print the current tx in a txt file (and add it to the other tx if it s not the first loop of this block)
./particl-cli decoderawtransaction $rawtx >> ../CountMADescrow/lasttxidsearch.txt 2>/dev/null

#how much multisig address in this txid
nbmultisig=$(cat ../CountMADescrow/lasttxidsearch.txt | grep -A 10 blind | cut -c12- | grep -E ^R | sed 's/"//' | wc -l)


multisigcount=0
#A raw tx decoded show exactly 2 occurences of the same multisig address when there is a madescrow so let s check all the multisig address of this txid to know if they are identical
while [ "$multisigcount" -lt "$nbmultisig" ]
do

line1=$(printf '%.3f\n' "$(echo "$multisigcount" "+" "1" | bc -l )")
line1=$(echo "$line1" | cut -d "." -f 1 | cut -d "," -f 1)

line2=$(printf '%.3f\n' "$(echo "$multisigcount" "+" "2" | bc -l )")
line2=$(echo "$line1" | cut -d "." -f 1 | cut -d "," -f 1)

#a multisig address begin by R and a madescrow is made using Confidential transaction (blind)
multisig1=$(cat ../CountMADescrow/lasttxidsearch.txt | grep -A 10 blind |  grep -A 4 scripthash | cut -c12- | grep -E ^R | sed 's/"//' | sed -n "$line1 p")
multisig2=$(cat ../CountMADescrow/lasttxidsearch.txt | grep -A 10 blind |  grep -A 4 scripthash | cut -c12- | grep -E ^R | sed 's/"//' | sed -n "$line2 p")

if [[ "$multisig1" = "$multisig2"  ]] ; then

#increase madtxid counter if there are madescrows in this txid
madtxid=$(printf '%.3f\n' "$(echo "$madtxid" "+" "1" | bc -l )")
madtxid=$(echo "$madtxid" | cut -d "." -f 1 | cut -d "," -f 1)

#it s an escrow involving 2transactions which are going to the same multisig address so if multisig1(buyer tx to the multisig1)=multisig2(seller tx to the multisig2) in this txid multisig2 != multisig3, this line should optimize the script
multisigcount=$(($multisigcount + 1))

echo "$multisig1" >> ../CountMADescrow/madlist.txt
echo "" >> ../CountMADescrow/madlist.txt
fi


multisigcount=$(($multisigcount + 1))
done


#increase the madblock counter if there are madescrows in this block
madblock=$(printf '%.3f\n' "$(echo "$madtxid" "+" "$madblock" | bc -l )")
madblock=$(echo "$madblock" | cut -d "." -f 1 | cut -d "," -f 1)


#delete the txt file to have a new one empty for the next block and reinitialize "$madtxid"
rm ../CountMADescrow/lasttxidsearch.txt  2>/dev/null

currenttx=$(($currenttx + 1))
done
clear

[ -f ../CountMADescrow/madlist.txt ] && madlist=$(cat ../CountMADescrow/madlist.txt)  2>/dev/null
echo -e "${yel}$madblock MADESCROW(S) CREATED IN THE BLOCK $currentblock ${neutre}"
echo ""
echo -e "${gr}$madlist${neutre}"
echo ""
rm ../CountMADescrow/madlist.txt  2>/dev/null
