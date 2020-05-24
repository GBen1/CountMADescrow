#!/bin/bash


yel='\e[1;33m'
neutre='\e[0;m'
gr='\e[1;32m'
red='\e[1;31m'
bl='\e[1;36m'
flred='\e[1;41m'


numadtot=0
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
rm ../CountMADescrow/madlist.txt


blockhash=$(./particl-cli getblockstats $blockdisplay | grep blockhash | sed 's/.* //' | sed 's/"//' | sed 's/"//' | sed 's/,//')



txcount=$(./particl-cli getblock $blockhash | cut -c5- | grep "^\"" | sed 's/"//' | sed 's/"//' | sed 's/,//' | wc -l)
currenttx=1
txcount=$(($txcount + 1))

numad=0


# for each tx in this block do:
while [ "$txcount" -gt "$currenttx" ]
do
txid=$(./particl-cli getblock $blockhash | cut -c5- | grep "^\"" | sed 's/"//' | sed 's/"//' | sed 's/,//' | sed -n "$currenttx p")





rawtx=$(./particl-cli getrawtransaction $txid)

./particl-cli decoderawtransaction $rawtx >> ../CountMADescrow/lastblocksearch.txt


numad=$(./particl-cli decoderawtransaction $rawtx | grep -A 10 blind | cut -c12- | grep -E ^R | sed -n '1~2p' | wc -l)
numadtot= "$numadtot" + "$numad"

echo "" >> ../CountMADescrow/madlist.txt
echo $blockdisplay >> ../CountMADescrow/madlist.txt
echo "" >> ../CountMADescrow/madlist.txt
madlist=$(./particl-cli decoderawtransaction $rawtx | grep -A 10 blind | cut -c12- | grep -E ^R | sed -n '1~2p') >> ../CountMADescrow/madlist.txt


currenttx=$(($currenttx + 1))
done

echo "$numadtot in the block "$blockdisplay"
cat ../madlist.txt

