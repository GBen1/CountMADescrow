#!/bin/bash


yel='\e[1;33m'
neutre='\e[0;m'
gr='\e[1;32m'
red='\e[1;31m'
bl='\e[1;36m'
flred='\e[1;41m'



$blockdisplay=0
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
./particl-cli decoderawtransaction $rawtx



currenttx=$(($currenttx + 1))
done

 cat ../CountMADescrow/lastblocksearch.txt | grep -A 10 blind | cut -c12- | grep -E ^R | sed -n '1~2p' -wc -l
 cat ../CountMADescrow/lastblocksearch.txt | grep -A 10 blind | cut -c12- | grep -E ^R | sed -n '1~2p'
