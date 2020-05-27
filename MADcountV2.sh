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

#delete this file to not keep the informations of the latest txid scanned if this script has already been launched and stoped before the end of the loop
rm ../CountMADescrow/lasttxidsearch.txt 2>/dev/null

#what is the highest block synchronized on this node ?
latestblock=$(./particl-cli getblockcount) 

currentblock=0
while ((currentblock < 506468))
do
clear
#It s not useful t start counting before the block 506468 for the reason explained below
echo -e "${red}The first Private MADescrow has been created during the block 506469 we are at the block $latestblock ${neutre}"
echo -e "${yel}From which block do you want to count the Private MADescrow creations ?${neutre}${gr}[506468;$latestblock]${neutre}" && read currentblock
currentblock=$(echo $currentblock | cut -d "." -f 1 | cut -d "," -f 1 | tr -d [a-zA-Z]| sed -n '/^[[:digit:]]*$/p' )
beginning=$(echo $currentblock | cut -d "." -f 1 | cut -d "," -f 1 | tr -d [a-zA-Z]| sed -n '/^[[:digit:]]*$/p' )
done

#These lines are going to be useful is you want to make your own graph:
date=$(date | sed 's/ //' |  sed 's/ //'  |  sed 's/ //'  |  sed 's/ //'  |  sed 's/ //')
weeklygraph=$beginning
monthlygraph=$beginning
quartergraph=$beginning
yeargraph=$beginning

echo "clear" > ../CountMADescrow/displaylaststats.sh
echo "neutre='\e[0;m'" >> ../CountMADescrow/displaylaststats.sh
echo "flred='\e[1;41m'" >> ../CountMADescrow/displaylaststats.sh
echo -e "${flred}BLOCK BASED STATS${neutre}" >> ../CountMADescrow/displaylaststats.sh
echo "" >> ../CountMADescrow/displaylaststats.sh
echo "cat MYGRAPHS/$date/yeargraph.txt" >> ../CountMADescrow/displaylaststats.sh
echo "cat MYGRAPHS/$date/quartergraph.txt" >> ../CountMADescrow/displaylaststats.sh
echo "cat MYGRAPHS/$date/monthlygraph.txt" >> ../CountMADescrow/displaylaststats.sh
echo "cat MYGRAPHS/$date/weeklygraph.txt" >> ../CountMADescrow/displaylaststats.sh


#initialize the counter
madtot=0
#for each block do...
while [ "$latestblock" -gt "$currentblock" ]
do 

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
multisig1=$(cat ../CountMADescrow/lasttxidsearch.txt | grep -A 10 blind | cut -c12- | grep -E ^R | sed 's/"//' | sed -n "$line1 p")
multisig2=$(cat ../CountMADescrow/lasttxidsearch.txt | grep -A 10 blind | cut -c12- | grep -E ^R | sed 's/"//' | sed -n "$line2 p")

if [[ "$multisig1" = "$multisig2"  ]] ; then

#increase madtxid counter if there are madescrows in this txid
madtxid=$(printf '%.3f\n' "$(echo "$madtxid" "+" "1" | bc -l )")
madtxid=$(echo "$madtxid" | cut -d "." -f 1 | cut -d "," -f 1)

#it s an escrow involving 2transactions which are going to the same multisig address so if multisig1(buyer tx to the multisig1)=multisig2(seller tx to the multisig2) in this txid multisig2 != multisig3, this line should optimize the script
multisigcount=$(($multisigcount + 1))
fi


multisigcount=$(($multisigcount + 1))
done


#Increase madblock if there was a Madescrow in the last txid scanned
madblock=$(printf '%.3f\n' "$(echo "$madtxid" "+" "$madblock" | bc -l )")
madblock=$(echo "$madblock" | cut -d "." -f 1 | cut -d "," -f 1)

#MAKE YOUR OWN GRAPH  !
#Check the results in the folder "MYGRAPH" at the end of this script or just enter "bash displaylaststats.sh" to display the last stats
#Note: 520063 = first block of september 2019

#WEEKLY GRAPH

if [[ "$currentblock" -eq "$weeklygraph" ]] ; then
if [[ "$currentblock" -eq "$beginning" ]] ; then
mkdir ../CountMADescrow/MYGRAPHS 2>/dev/null
mkdir ../CountMADescrow/MYGRAPHS/$date 2>/dev/null
echo -e "${red}GRAPH: EVERY WEEK (5040 blocks) ${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/weeklygraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/weeklygraph.txt
weeklygraph=$(($weeklygraph + 5040)) 
else
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROWS CREATED FROM THE BLOCK ${neutre}${yel}$beginning${neutre}${gr} TO THE BLOCK ${neutre}${yel}$currentblock${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/weeklygraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/weeklygraph.txt
weeklygraph=$(($weeklygraph + 5040)) 
fi
fi

#MONTHLY GRAPH

if [[ "$currentblock" -eq "$monthlygraph" ]] ; then
if [[ "$currentblock" -eq "$beginning" ]] ; then
mkdir ../CountMADescrow/MYGRAPHS 2>/dev/null
mkdir ../CountMADescrow/MYGRAPHS/$date 2>/dev/null
echo -e "${red}GRAPH: EVERY MONTH (21600 blocks) ${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/monthlygraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/monthlygraph.txt
monthlygraph=$(($monthlygraph + 21600)) 
else
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROWS CREATED FROM THE BLOCK ${neutre}${yel}$beginning${neutre}${gr} TO THE BLOCK ${neutre}${yel}$currentblock${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/monthlygraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/monthlygraph.txt
monthlygraph=$(($monthlygraph + 21600)) 
fi
fi

#QUARTERLY

if [[ "$currentblock" -eq "$quartergraph" ]] ; then
if [[ "$currentblock" -eq "$beginning" ]] ; then
mkdir ../CountMADescrow/MYGRAPHS 2>/dev/null
mkdir ../CountMADescrow/MYGRAPHS/$date 2>/dev/null
echo -e "${red}GRAPH: EVERY QUARTER (64800 blocks) ${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/quartergraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/quartergraph.txt
quartergraphh=$(($quartergraph + 64800)) 
else
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROWS CREATED FROM THE BLOCK ${neutre}${yel}$beginning${neutre}${gr} TO THE BLOCK ${neutre}${yel}$currentblock${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/quartergraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/quartergraph.txt
quartergraph=$(($quartergraph + 64800)) 
fi
fi


#YEARLY

if [[ "$currentblock" -eq "$yeargraph" ]] ; then
if [[ "$currentblock" -eq "$beginning" ]] ; then
mkdir ../CountMADescrow/MYGRAPHS 2>/dev/null
mkdir ../CountMADescrow/MYGRAPHS/$date 2>/dev/null
echo -e "${red}GRAPH: EVERY YEAR (259200 blocks) ${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/yeargraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/yeargraph.txt
yeargraph=$(($yeargraphgraph + 259200)) 
else
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROWS CREATED FROM THE BLOCK ${neutre}${yel}$beginning${neutre}${gr} TO THE BLOCK ${neutre}${yel}$currentblock${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/yeargraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/yeargraphgraph.txt
yeargraph=$(($yeargraph + 259200)) 
fi
fi


#delete the txt file to have a new one empty for the next block and reinitialize "$madtxid"
rm ../CountMADescrow/lasttxidsearch.txt  2>/dev/null

currenttx=$(($currenttx + 1))
done



#increase the madescrow counter if there are madescrows in this block
madtot=$(printf '%.3f\n' "$(echo "$madtot" "+" "$madblock" | bc -l )")
madtot=$(echo "$madtot" | cut -d "." -f 1 | cut -d "," -f 1)


echo -e "${yel}$madblock${neutre} ${gr}PRIVATE MADESCROW CREATED IN THE BLOCK ${neutre}${yel}$currentblock${neutre}"
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROWS CREATED SINCE THE BLOCK ${neutre}${yel}$beginning${neutre}"
echo ""


currentblock=$(($currentblock + 1)) 
done
