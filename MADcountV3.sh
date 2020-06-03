#!/bin/bash


yel='\e[1;33m'
neutre='\e[0;m'
gr='\e[1;32m'
red='\e[1;31m'
bl='\e[1;36m'
flred='\e[1;41m'
flblue='\e[1;44m'

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
highestblock=$(($highestblock - 1))
if [[ "$checksynced" -lt "$highestblock" ]] ; then
echo -e "${flred}ERROR: THE BLOCKCHAIN IS NOT FULLY SYNCHRONIZED: $checksynced < $highestblock ${neutre}" 
echo -e "${flred}TRY AGAIN IN FEW MINUTES ${neutre}"
exit
fi

#delete this file to not keep the informations of the latest txid scanned if this script has already been launched and stoped before the end of the loop
rm ../CountMADescrow/lasttxidsearch.txt 2>/dev/null

date=$(date | sed 's/ //' |  sed 's/ //'  |  sed 's/ //'  |  sed 's/ //'  |  sed 's/ //' | sed 's/ //' )

#what is the highest block synchronized on this node ?
latestblock=$(./particl-cli getblockcount) 
highestblock=$(./particl-cli getblockcount)

currentblock=0
while ((currentblock < 506469)) || ((latestblock <= currentblock))
do
clear
#It s not useful to start counting before the block 506469 for the reasons explained below
echo -e "${yel}The first Private MADescrow has been created during the block 506469 and we are at the block $latestblock ${neutre}"
echo -e "${yel}From which block do you want to count the Private MADescrow creations ?${neutre}${gr} [506469;$latestblock[${neutre}" && read currentblock
currentblock=$(echo $currentblock | cut -d "." -f 1 | cut -d "," -f 1 | tr -d [a-zA-Z]| sed -n '/^[[:digit:]]*$/p' )
beginning=$(echo $currentblock | cut -d "." -f 1 | cut -d "," -f 1 | tr -d [a-zA-Z]| sed -n '/^[[:digit:]]*$/p' )
done

latestblock=0
while ((latestblock <= currentblock))
do
clear
#It s not useful t start counting before the block 506469 for the reasons explained below
echo -e "${yel}You are going to start counting the Private MADescrows from the block ${neutre}${gr}$currentblock ${neutre}${yel}and we are at the block $highestblock ${neutre}"
echo -e "${yel}To which block do you want to count the Private MADescrow creations ?${neutre}${gr} ]$currentblock;$highestblock]${neutre}" && read latestblock
currentblock=$(echo $currentblock | cut -d "." -f 1 | cut -d "," -f 1 | tr -d [a-zA-Z]| sed -n '/^[[:digit:]]*$/p' )
beginning=$(echo $currentblock | cut -d "." -f 1 | cut -d "," -f 1 | tr -d [a-zA-Z]| sed -n '/^[[:digit:]]*$/p' )
done

#These lines are going to be useful is you want to make your own graph:

weeklygraph=$beginning
monthlygraph=$beginning
quartergraph=$beginning
yeargraph=$beginning

#create displaylaststats.sh
echo "clear" > ../CountMADescrow/displaylaststats.sh
echo "[ -f  ../CountMADescrow/MYGRAPHS/$date/madlist.txt ] && numadlist=\$(cat MYGRAPHS/$date/madlist.txt 2>/dev/null | wc -l)" >> ../CountMADescrow/displaylaststats.sh
echo "[ -f  ../CountMADescrow/MYGRAPHS/$date/reliabilityindex.txt ] && index=\$(cat MYGRAPHS/$date/reliabilityindex.txt 2>/dev/null)" >> ../CountMADescrow/displaylaststats.sh
echo "[ -f  ../CountMADescrow/MYGRAPHS/$date/fakelist.txt ] && fakelist=\$(cat MYGRAPHS/$date/fakelist.txt 2>/dev/null)" >> ../CountMADescrow/displaylaststats.sh
echo "[ -f  ../CountMADescrow/MYGRAPHS/$date/released.txt ] && released=\$(cat MYGRAPHS/$date/released.txt 2>/dev/null)" >> ../CountMADescrow/displaylaststats.sh
echo "[ \$released ] && G=\$(printf '%.3f\n' \"\$(echo \"\$released\" \"*\" \"100\" | bc -l )\")" >> ../CountMADescrow/displaylaststats.sh
echo "[ \$numadlist ] && [ \$G ] && H=\$(printf '%.3f\n' \"\$(echo \"\$G\" \"/\" \"\$numadlist\" | bc -l )\")" >> ../CountMADescrow/displaylaststats.sh
echo "[ \$H ] &&  releaseindex=\$(echo \"\$H\" | cut -d \".\" -f 1 | cut -d \",\" -f 1)" >> ../CountMADescrow/displaylaststats.sh
echo "[ \$fakelist ] && F=\$(printf '%.3f\n' \"\$(echo \"\$fakelist\" \"*\" \"100\" | bc -l )\")" >> ../CountMADescrow/displaylaststats.sh
echo "[ \$numadlist ] && [ \$F ] && Z=\$(printf '%.3f\n' \"\$(echo \"\$F\" \"/\" \"\$numadlist\" | bc -l )\")" >> ../CountMADescrow/displaylaststats.sh
echo "[ \$Z ] &&  fakeindex=\$(echo \"\$Z\" | cut -d \".\" -f 1 | cut -d \",\" -f 1)" >> ../CountMADescrow/displaylaststats.sh
echo "echo -e \"\e[1;44mTIME BASED STATS (Available from 08-11-19 (block 506469) to 06-01-20 (block 703701)\e[0;m\"" >> ../CountMADescrow/displaylaststats.sh
echo "echo \"\" " >> ../CountMADescrow/displaylaststats.sh
echo "echo -e \"\e[1;31mEVERY MONTH (TIME BASED)\e[0;m\"" >> ../CountMADescrow/displaylaststats.sh
echo "echo \"\" " >> ../CountMADescrow/displaylaststats.sh
echo "cat MYGRAPHS/$date/timebasedgraph.txt 2>/dev/null" >> ../CountMADescrow/displaylaststats.sh
echo "echo \"\" " >> ../CountMADescrow/displaylaststats.sh
echo "read -p \"\$(echo -e \"\e[1;36mPress [Enter] key to continue...\e[0;m\")\"" >> ../CountMADescrow/displaylaststats.sh
echo "clear" >> ../CountMADescrow/displaylaststats.sh
echo "cat MYGRAPHS/$date/yeargraph.txt" >> ../CountMADescrow/displaylaststats.sh
echo "cat MYGRAPHS/$date/quartergraph.txt" >> ../CountMADescrow/displaylaststats.sh
echo "cat MYGRAPHS/$date/monthlygraph.txt" >> ../CountMADescrow/displaylaststats.sh
echo "echo \"\" " >> ../CountMADescrow/displaylaststats.sh
echo "read -p \"\$(echo -e \"\e[1;36mPress [Enter] key to continue...\e[0;m\")\"" >> ../CountMADescrow/displaylaststats.sh
echo "clear" >> ../CountMADescrow/displaylaststats.sh
echo "echo -e \"\e[1;44mBLOCK BASED STATS\e[0;m\"" >> ../CountMADescrow/displaylaststats.sh
echo "echo \"\" " >> ../CountMADescrow/displaylaststats.sh
echo "cat MYGRAPHS/$date/weeklygraph.txt" >> ../CountMADescrow/displaylaststats.sh
echo "echo \"\" " >> ../CountMADescrow/displaylaststats.sh
echo "read -p \"\$(echo -e \"\e[1;36mPress [Enter] key to continue...\e[0;m\")\"" >> ../CountMADescrow/displaylaststats.sh
echo "clear" >> ../CountMADescrow/displaylaststats.sh
echo "echo -e \"\e[1;44m\$numadlist MADESCROWS FOUND\e[0;m\"" >> ../CountMADescrow/displaylaststats.sh
echo "[ -f  ../CountMADescrow/MYGRAPHS/$date/fakelist.txt ] && echo -e \"\e[1;41m\$fakelist FAKE MADESCROWS FOUND\e[0;m\"" >> ../CountMADescrow/displaylaststats.sh
echo "[ -f  ../CountMADescrow/MYGRAPHS/$date/released.txt ] && echo -e \"\e[1;42m\$released MADESCROWS HAVE BEEN RELEASED\e[0;m\"" >> ../CountMADescrow/displaylaststats.sh
echo "echo \"\" " >> ../CountMADescrow/displaylaststats.sh
echo "[ -f  ../CountMADescrow/MYGRAPHS/$date/reliabilityindex.txt ] && echo -e \"\e[1;44m\$index\e[0;m\"" >> ../CountMADescrow/displaylaststats.sh
echo "[ \$fakeindex ] && echo -e \"\e[1;41mFAKE INDEX = \$fakeindex %\e[0;m\"" >> ../CountMADescrow/displaylaststats.sh
echo "[ \$releaseindex ] && echo -e \"\e[1;42mRELEASE INDEX = \$releaseindex %\e[0;m\"" >> ../CountMADescrow/displaylaststats.sh
echo "echo \"\" " >> ../CountMADescrow/displaylaststats.sh
echo "cat MYGRAPHS/$date/madlist.txt 2>/dev/null" >> ../CountMADescrow/displaylaststats.sh




#initialize the counters
madtot=0
isfake=0
madlist=0
released=0
timebasedcounter=0
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

#how much multisig address in this txid ?, a multisig address begins by R (grep -E ^R) and a madescrow is made using Confidential transaction (grep blind), moreover a script is involved (grep scripthash)
nbmultisig=$(cat ../CountMADescrow/lasttxidsearch.txt | grep -A 10 blind | grep -A 4 scripthash | cut -c12- | grep -E ^R | sed 's/"//' | wc -l)
#Could eventually be better than the previous line (by being more specific about the kind of script involved = P2SH): nbmultisig=$(cat ../CountMADescrow/lasttxidsearch.txt | grep -A 10 blind | grep -A 7 OP_HASH160 | grep -A 7 OP_EQUAL | grep -A 7 a914 | grep -A 7 87 | grep -A 4 scripthash | cut -c12- | grep -E ^R | sed 's/"//'| wc -l)

multisigcount=0
#A raw tx decoded show exactly 2 occurences of the same multisig address when there is a madescrow so let s check all the multisig address of this txid to know if they are identical
while [ "$multisigcount" -lt "$nbmultisig" ]
do

line1=$(printf '%.3f\n' "$(echo "$multisigcount" "+" "1" | bc -l )")
line1=$(echo "$line1" | cut -d "." -f 1 | cut -d "," -f 1)

line2=$(printf '%.3f\n' "$(echo "$multisigcount" "+" "2" | bc -l )")
line2=$(echo "$line1" | cut -d "." -f 1 | cut -d "," -f 1)


multisig1=$(cat ../CountMADescrow/lasttxidsearch.txt | grep -A 10 blind |  grep -A 4 scripthash | cut -c12- | grep -E ^R | sed 's/"//' | sed -n "$line1 p")
multisig2=$(cat ../CountMADescrow/lasttxidsearch.txt | grep -A 10 blind |  grep -A 4 scripthash | cut -c12- | grep -E ^R | sed 's/"//' | sed -n "$line2 p")
#Could eventually be better than the previous lines (by being more specific about the kind of script involved = P2SH): multisig1=$(cat ../CountMADescrow/lasttxidsearch.txt  | grep -A 10 blind | grep -A 7 OP_HASH160 | grep -A 7 OP_EQUAL | grep -A 7 a914 | grep -A 7 87 | grep -A 4 scripthash | cut -c12- | grep -E ^R | sed 's/"//'| sed -n "$line1 p")
#Could eventually be better than the previous lines (by being more specific about the kind of script involved = P2SH): multisig2=$(cat ../CountMADescrow/lasttxidsearch.txt  | grep -A 10 blind | grep -A 7 OP_HASH160 | grep -A 7 OP_EQUAL | grep -A 7 a914 | grep -A 7 87 | grep -A 4 scripthash | cut -c12- | grep -E ^R | sed 's/"//'| sed -n "$line2 p")

if [[ "$multisig1" = "$multisig2"  ]] ; then

#increase the madtxid counter for each madescrow in this txid
madtxid=$(printf '%.3f\n' "$(echo "$madtxid" "+" "1" | bc -l )")
madtxid=$(echo "$madtxid" | cut -d "." -f 1 | cut -d "," -f 1)

#LET S VERIFY IF THE REAL MADESCROW IS AN OBVIOUS FAKE SALE AND/OR IF IT HAS BEEN RELEASED:
getmadtx=$($curl_cmd https://explorer.particl.io/particl-insight-api/addr/$multisig1 2>/dev/null | jq -r .transactions)
checkreleased=$(echo "$getmadtx" | wc -c)
r=0
if [[ "$checkreleased" -gt 100  ]] ; then
r=1
released=$(($released + 1))
fi

#get madescrow creation
tx2=$(echo $getmadtx | sed 's/ //' | sed 's/ //' | sed 's/ //' | sed 's/"//' | sed 's/"//' | sed 's/"//' | sed 's/"//' | cut -c2- | rev | cut -c2- | rev | sed 's/.*,//')
#get madescrow release tx
tx1=$(echo $getmadtx | sed 's/ //' | sed 's/ //' | sed 's/ //' | sed 's/"//' | sed 's/"//' | sed 's/"//' | sed 's/"//' | cut -c2- | rev | cut -c2- | sed 's/.*,//' | rev)



#get blockheight of madescrow creation
getblockmadtx2=$($curl_cmd https://explorer.particl.io/particl-insight-api/tx/$tx2 2>/dev/null | jq -r .blockheight)
#get blockheight of madescrow release
getblockmadtx1=$($curl_cmd https://explorer.particl.io/particl-insight-api/tx/$tx1 2>/dev/null | jq -r .blockheight)


difftx=$(printf '%.3f\n' "$(echo "$getblockmadtx1" "-" "$getblockmadtx2" | bc -l )")
difftx=$(echo "$difftx" | cut -d "." -f 1 | cut -d "," -f 1)

#patch
if [[ "$tx1" = "$tx2"  ]] ; then
difftx=40
fi

if [[ "$r" -eq 0 ]] ; then
 if [[ "$difftx" -lt 30 ]] ; then
  if [[ "$madlist" -eq 0 ]] ; then
  mkdir ../CountMADescrow/MYGRAPHS 2>/dev/null
  mkdir ../CountMADescrow/MYGRAPHS/$date 2>/dev/null
  echo -e "${gr}BLOCK ${neutre}${yel}$currentblock ${neutre}${gr}: $multisig1${neutre} ${red}(FAKE)${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/madlist.txt
  isfake=$(($isfake + 1))
  madlist=$(($madlist + 1)) 
  else
  echo -e "${gr}BLOCK ${neutre}${yel}$currentblock ${neutre}${gr}: $multisig1${neutre} ${red}(FAKE)${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/madlist.txt
  isfake=$(($isfake + 1))
  fi

 else
  if [[ "$madlist" -eq 0 ]] ; then
  mkdir ../CountMADescrow/MYGRAPHS 2>/dev/null
  mkdir ../CountMADescrow/MYGRAPHS/$date 2>/dev/null
  echo -e "${gr}BLOCK ${neutre}${yel}$currentblock ${neutre}${gr}: $multisig1${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/madlist.txt
  madlist=$(($madlist + 1)) 
    else
  echo -e "${gr}BLOCK ${neutre}${yel}$currentblock ${neutre}${gr}: $multisig1${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/madlist.txt
    fi
 fi

else
 if [[ "$difftx" -lt 30 ]] ; then
  if [[ "$madlist" -eq 0 ]] ; then
  mkdir ../CountMADescrow/MYGRAPHS 2>/dev/null
  mkdir ../CountMADescrow/MYGRAPHS/$date 2>/dev/null
  echo -e "${gr}BLOCK ${neutre}${yel}$currentblock ${neutre}${gr}: $multisig1${neutre} ${red}(FAKE) ${neutre}${bl}(RELEASED)${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/madlist.txt
  isfake=$(($isfake + 1))
  madlist=$(($madlist + 1)) 
  else
  echo -e "${gr}BLOCK ${neutre}${yel}$currentblock ${neutre}${gr}: $multisig1${neutre} ${red}(FAKE) ${neutre}${bl}(RELEASED)${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/madlist.txt
  isfake=$(($isfake + 1))
  fi

 else
  if [[ "$madlist" -eq 0 ]] ; then
  mkdir ../CountMADescrow/MYGRAPHS 2>/dev/null
  mkdir ../CountMADescrow/MYGRAPHS/$date 2>/dev/null
  echo -e "${gr}BLOCK ${neutre}${yel}$currentblock ${neutre}${gr}: $multisig1${neutre}${bl}(RELEASED)${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/madlist.txt
  madlist=$(($madlist + 1)) 
  else
  echo -e "${gr}BLOCK ${neutre}${yel}$currentblock ${neutre}${gr}: $multisig1${neutre}${bl}(RELEASED)${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/madlist.txt
  fi
 fi
fi

#it s an escrow involving 2transactions which are going to the same multisig address so if multisig1(buyer tx to the multisig1)=multisig2(seller tx to the multisig2) in this txid multisig2 != multisig3, this line should optimize the script
multisigcount=$(($multisigcount + 1))
fi


multisigcount=$(($multisigcount + 1))
done


#Increase madblock if there was a Madescrow in the last txid scanned
madblock=$(printf '%.3f\n' "$(echo "$madtxid" "+" "$madblock" | bc -l )")
madblock=$(echo "$madblock" | cut -d "." -f 1 | cut -d "," -f 1)


#delete the txt file to have a new one empty for the next txid and reinitialize "$madtxid"
rm ../CountMADescrow/lasttxidsearch.txt  2>/dev/null

currenttx=$(($currenttx + 1))
done


#increase the madescrow counter if there are madescrows in this block
madtot=$(printf '%.3f\n' "$(echo "$madtot" "+" "$madblock" | bc -l )")
madtot=$(echo "$madtot" | cut -d "." -f 1 | cut -d "," -f 1)


echo -e "${yel}$madblock${neutre} ${gr}PRIVATE MADESCROW CREATED IN THE BLOCK ${neutre}${yel}$currentblock${neutre}"
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROWS CREATED SINCE THE BLOCK ${neutre}${yel}$beginning${neutre}"
echo ""

#MAKE YOUR OWN GRAPH  !
#Check the results in the folder "MYGRAPH" at the end of this script or just enter "bash displaylaststats.sh" to display the last stats of your last search at the end of the script


#WEEKLY GRAPH

if [[ "$currentblock" -eq "$weeklygraph" ]] ; then
if [[ "$currentblock" -eq "$beginning" ]] ; then
mkdir ../CountMADescrow/MYGRAPHS 2>/dev/null
mkdir ../CountMADescrow/MYGRAPHS/$date 2>/dev/null
echo -e "${red}EVERY WEEK (5089 blocks) ${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/weeklygraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/weeklygraph.txt
weeklygraph=$(($weeklygraph + 5089)) 
else
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROWS CREATED FROM THE BLOCK ${neutre}${yel}$beginning${neutre}${gr} TO THE BLOCK ${neutre}${yel}$currentblock${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/weeklygraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/weeklygraph.txt
weeklygraph=$(($weeklygraph + 5089)) 
fi
fi

#MONTHLY GRAPH

if [[ "$currentblock" -eq "$monthlygraph" ]] ; then
if [[ "$currentblock" -eq "$beginning" ]] ; then
mkdir ../CountMADescrow/MYGRAPHS 2>/dev/null
mkdir ../CountMADescrow/MYGRAPHS/$date 2>/dev/null
echo -e "${red}EVERY MONTH (20354 blocks) ${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/monthlygraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/monthlygraph.txt
monthlygraph=$(($monthlygraph + 20354)) 
else
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROWS CREATED FROM THE BLOCK ${neutre}${yel}$beginning${neutre}${gr} TO THE BLOCK ${neutre}${yel}$currentblock${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/monthlygraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/monthlygraph.txt
monthlygraph=$(($monthlygraph + 20354)) 
fi
fi

#QUARTERLY

if [[ "$currentblock" -eq "$quartergraph" ]] ; then
if [[ "$currentblock" -eq "$beginning" ]] ; then
mkdir ../CountMADescrow/MYGRAPHS 2>/dev/null
mkdir ../CountMADescrow/MYGRAPHS/$date 2>/dev/null
echo -e "${red}EVERY QUARTER (61063 blocks) ${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/quartergraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/quartergraph.txt
quartergraph=$(($quartergraph + 61063)) 
else
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROWS CREATED FROM THE BLOCK ${neutre}${yel}$beginning${neutre}${gr} TO THE BLOCK ${neutre}${yel}$currentblock${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/quartergraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/quartergraph.txt
quartergraph=$(($quartergraph + 61063)) 
fi
fi


#YEARLY

if [[ "$currentblock" -eq "$yeargraph" ]] ; then
if [[ "$currentblock" -eq "$beginning" ]] ; then
mkdir ../CountMADescrow/MYGRAPHS 2>/dev/null
mkdir ../CountMADescrow/MYGRAPHS/$date 2>/dev/null
echo -e "${flblue}BLOCK BASED STATS${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/yeargraph.txt
echo "" >> ../CountMADescrow/MYGRAPHS/$date/yeargraph.txt
echo -e "${red}EVERY YEAR (244253 blocks) ${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/yeargraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/yeargraph.txt
yeargraph=$(($yeargraphh + 244253)) 
else
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROWS CREATED FROM THE BLOCK ${neutre}${yel}$beginning${neutre}${gr} TO THE BLOCK ${neutre}${yel}$currentblock${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/yeargraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/yeargraph.txt
yeargraph=$(($yeargraph + 244253)) 
fi
fi

#TIME BASED GRAPH


if [[ "$currentblock" -eq 520062 ]] || [[ "$currentblock" -eq 540170 ]] || [[ "$currentblock" -eq 560954 ]] || [[ "$currentblock" -eq  581066 ]] || [[ "$currentblock" -eq 601840 ]] || [[ "$currentblock" -eq 622585 ]] || [[ "$currentblock" -eq 642016 ]] || [[ "$currentblock" -eq 662773 ]] || [[ "$currentblock" -eq 682896 ]] || [[ "$currentblock" -eq 703701 ]]; then
if [[ "$currentblock" -eq 520062 ]]; then
themonth=$(echo "August 2019")
elif [[ "$currentblock" -eq 540170 ]]; then
themonth=$(echo "September 2019")
elif [[ "$currentblock" -eq 560954 ]]; then
themonth=$(echo "October 2019")
elif [[ "$currentblock" -eq 581066 ]]; then
themonth=$(echo "November 2019")
elif [[ "$currentblock" -eq 601840 ]]; then
themonth=$(echo "December 2019")
elif [[ "$currentblock" -eq 622585 ]]; then
themonth=$(echo "January 2020")
elif [[ "$currentblock" -eq 642016 ]]; then
themonth=$(echo "February 2020")
elif [[ "$currentblock" -eq 662773 ]]; then
themonth=$(echo "March 2020")
elif [[ "$currentblock" -eq 682896 ]]; then
themonth=$(echo "April 2020")
elif [[ "$currentblock" -eq 703701 ]]; then
themonth=$(echo "May 2020")
fi

if [[ "$timebasedcounter" -eq 0 ]] ; then
mkdir ../CountMADescrow/MYGRAPHS 2>/dev/null
mkdir ../CountMADescrow/MYGRAPHS/$date 2>/dev/null
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROWS CREATED FROM THE BLOCK ${neutre}${yel}$beginning${neutre}${gr} TO THE END OF${neutre}${yel} $themonth ${neutre}${gr}(block${neutre}${yel} $currentblock${neutre}${gr})${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/timebasedgraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/timebasedgraph.txt
timebasedcounter=$(($timebasedcounter + 1)) 
else
echo -e "${yel}$madtot${neutre} ${gr}PRIVATE MADESCROWS CREATED FROM THE BLOCK ${neutre}${yel}$beginning${neutre}${gr} TO THE END OF${neutre}${yel} $themonth ${neutre}${gr}(block${neutre}${yel} $currentblock${neutre}${gr})${neutre}" >> ../CountMADescrow/MYGRAPHS/$date/timebasedgraph.txt
echo ""   >> ../CountMADescrow/MYGRAPHS/$date/timebasedgraph.txt
fi
fi


currentblock=$(($currentblock + 1)) 
done

#how much fake madescrows detected?
echo -e "$isfake" >> ../CountMADescrow/MYGRAPHS/$date/fakelist.txt

#how much madescrow have been released ?
echo -e "$released" >> ../CountMADescrow/MYGRAPHS/$date/released.txt

#create a reliability index to estimate the minimal % of real sales among the real madescrows found

firstblock=$(cat -A ../CountMADescrow/MYGRAPHS/$date/madlist.txt | cut -c29- | rev | sed 's/.* //' | rev | sed -n "1p")
lastblock=$(cat -A ../CountMADescrow/MYGRAPHS/$date/madlist.txt | cut -c29- | rev | sed 's/.* //' | rev | tac | sed -n "1p")

nblockscanned=$(printf '%.3f\n' "$(echo "$lastblock" "-" "$firstblock" "+" "1" | bc -l )")
nblockscanned=$(echo "$nblockscanned" | cut -d "." -f 1 | cut -d "," -f 1)
blockfound=$(cat ../CountMADescrow/MYGRAPHS/$date/madlist.txt 2>/dev/null | wc -l)

if [[ "$nblockscanned" -gt "34000" ]] ; then 
clear
echo -e "\e[1;36mRELIABILITY INDEX CALCULATION, PLEASE WAIT...\e[0;m"
x=4
y=700
elif [[ "$nblockscanned" -gt "21000" ]] ; then 
clear
echo -e "\e[1;36mRELIABILITY INDEX CALCULATION, PLEASE WAIT...\e[0;m"
x=3.5
y=700
elif [[ "$nblockscanned" -gt "13000" ]] ; then 
clear
echo -e "\e[1;36mRELIABILITY INDEX CALCULATION, PLEASE WAIT...\e[0;m"
x=3
y=350
else
clear
echo -e "\e[1;36mEnter \"bash displaylaststats.sh\" to display the results of your last search\e[0;m"
exit
fi

average=$(printf '%.3f\n' "$(echo "$blockfound" "*" "$y" | bc -l )")
average=$(printf '%.3f\n' "$(echo "$average" "/" "$nblockscanned" | bc -l )")
average=$(printf '%.3f\n' "$(echo "$average" "*" "1000" | bc -l )")
average=$(echo "$average" | cut -d "." -f 1 | cut -d "," -f 1)

thaverage=$(printf '%.3f\n' "$(echo "$average" "*" "$x" | bc -l )")
thaverage=$(echo "$thaverage" | cut -d "." -f 1 | cut -d "," -f 1)


line1=1
line2=2
refblock1=$(cat -A ../CountMADescrow/MYGRAPHS/$date/madlist.txt | cut -c29-  |  rev | sed 's/.* //' | rev | sed -n "$line1 p")
refblock2=$(cat -A ../CountMADescrow/MYGRAPHS/$date/madlist.txt | cut -c29-  |  rev | sed 's/.* //' | rev | sed -n "$line2 p")
checkrefblock2=$(echo "$refblock2" | wc -c)
checkrefblock1=$(echo "$refblock1" | wc -c)



fake=0
while [ "$checkrefblock2" -gt "2" ]
do
z=0


refblock1=$(cat -A ../CountMADescrow/MYGRAPHS/$date/madlist.txt | cut -c29-  |  rev | sed 's/.* //' | rev | sed -n "$line1 p")

var=$(printf '%.3f\n' "$(echo "$refblock1" "+" "$y" | bc -l )")
var=$(echo "$var" | cut -d "." -f 1 | cut -d "," -f 1)

while (( refblock2 < var)) &&  (( checkrefblock2  >  2))
do
z=$(($z + 1000))
line2=$(($line2 + 1))
refblock2=$(cat -A ../CountMADescrow/MYGRAPHS/$date/madlist.txt | cut -c29-  |  rev | sed 's/.* //' | rev | sed -n "$line2 p")
checkrefblock2=$(echo "$refblock2" | wc -c)
done

line1=$(($line1 + 1))


if [[ "$z" -gt "$thaverage" ]] ; then

z=$(printf '%.3f\n' "$(echo "$z" "/" "1000" | bc -l )")
fake=$(printf '%.3f\n' "$(echo "$fake" "+" "$z" | bc -l )")
fake=$(echo "$fake" | cut -d "." -f 1 | cut -d "," -f 1)

fi


refblock1=$(cat -A ../CountMADescrow/MYGRAPHS/$date/madlist.txt | cut -c29-  |  rev | sed 's/.* //' | rev | sed -n "$line1 p")
checkrefblock2=$(echo "$refblock2" | wc -c)
done


fake=$(printf '%.3f\n' "$(echo "$fake" "*" "100" | bc -l )")
fake=$(printf '%.3f\n' "$(echo "$fake" "/" "$blockfound" | bc -l )")
fake=$(printf '%.3f\n' "$(echo "100" "-" "$fake" | bc -l )")
fake=$(echo "$fake" | cut -d "." -f 1 | cut -d "," -f 1)

echo "RELIABILITY INDEX = $fake %" > ../CountMADescrow/MYGRAPHS/$date/reliabilityindex.txt
clear
echo -e "\e[1;36mEnter \"bash displaylaststats.sh\" to display the results of your last search\e[0;m"

bash displaylaststats.sh 2>/dev/null
