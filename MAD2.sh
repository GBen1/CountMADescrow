#!/bin/bash


yel='\e[1;33m'
neutre='\e[0;m'
gr='\e[1;32m'
red='\e[1;31m'
bl='\e[1;36m'
flred='\e[1;41m'


cd
cd particlcore

rm ../CountMADescrow/lastblocksearch.txt

madtot=0
currentblock=688884
latestblock=$(./particl-cli getblockcount) 
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

numad=$(cat ../CountMADescrow/lastblocksearch.txt | grep -A 10 blind | cut -c12- | grep -E ^R | sed -n '1~2p' | sed 's/"//' | wc -l)



madtot=$(printf '%.3f\n' "$(echo "$madtot" "+" "$numad" | bc -l )")
madtot=$(echo "$madtot" | cut -d "." -f 1 | cut -d "," -f 1)

madblock=$(printf '%.3f\n' "$(echo "$madblock" "+" "$numad" | bc -l )")
madblock=$(echo "$madblock" | cut -d "." -f 1 | cut -d "," -f 1)

currenttx=$(($currenttx + 1))

done

echo "$madblock MADESCROW CREATED IN THE BLOCK $currentblock"
echo "$madtot MADESCROW CREATED FROM THE BEGINNING"
echo ""

madblock=0

rm ../CountMADescrow/lastblocksearch.txt

currentblock=$(($currentblock + 1)) 
done


echo "$madtot"
