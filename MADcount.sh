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

checksynced$(./particl-cli getblockcount)
if [[ "$checksynced" -lt 698663 ]] ; then
echo -e "${flred}ERROR: THE BLOCKCHAIN IS NOT FULLY SYNCHRONIZED ${neutre}" 
exit
fi

rm ../CountMADescrow/lastblocksearch.txt

latestblock=$(./particl-cli getblockcount) 

currentblock=0
while ((currentblock < 506468))
do
clear
echo -e "${red}The first Private MADescrow has been created during the block 506469 we are at the block $latestblock ${neutre}"
echo -e "${yel}From which block do you want to count the Private MADescrow creations ?${neutre}" && read currentblock
currentblock=$(echo $currentblock | cut -d "." -f 1 | cut -d "," -f 1 | tr -d [a-zA-Z]| sed -n '/^[[:digit:]]*$/p' )
beginning=$(echo $currentblock | cut -d "." -f 1 | cut -d "," -f 1 | tr -d [a-zA-Z]| sed -n '/^[[:digit:]]*$/p' )
done

madtot=0
#for each block do...
while [ "$latestblock" -gt "$currentblock" ]
do 



blockhash=$(./particl-cli getblockstats $currentblock | grep blockhash | sed 's/.* //' | sed 's/"//' | sed 's/"//' | sed 's/,//')

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

numad=$(cat ../CountMADescrow/lastblocksearch.txt | grep -A 10 blind | cut -c12- | grep -E ^R | sed -n '1~2p' | sed 's/"//' | wc -l)



madtot=$(printf '%.3f\n' "$(echo "$madtot" "+" "$numad" | bc -l )")
madtot=$(echo "$madtot" | cut -d "." -f 1 | cut -d "," -f 1)

madblock=$(printf '%.3f\n' "$(echo "$madblock" "+" "$numad" | bc -l )")
madblock=$(echo "$madblock" | cut -d "." -f 1 | cut -d "," -f 1)


echo -e "${yel}$madblock${neutre} ${gr}PRIVATE MADESCROW CREATED IN THE BLOCK $currentblock${neutre}"
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROW CREATED SINCE THE BLOCK $beginning${neutre}"
echo ""

madblock=0

rm ../CountMADescrow/lastblocksearch.txt

currentblock=$(($currentblock + 1)) 
done

