#!/bin/bash

#block=518023
#we should start at 0 but madescrow in this block (518023)

cd
cd particlcore


currentblock=698350
latestblock=$(./particl-cli getblockcount) 
#for each block do...
while [ "$latestblock" -gt "$currentblock" ]
do 

#####





blockhash=$(./particl-cli getblockstats $block | grep blockhash | sed 's/.* //' | sed 's/"//' | sed 's/"//' | sed 's/,//')

# for each tx in each block do:

txcount=$(./particl-cli getblock $blockhash | cut -c5- | grep "^\"" | sed 's/"//' | sed 's/"//' | sed 's/,//' | wc -l)
currenttx=1
txcount=$(($txcount + 1))

while [ "$txcount" -gt "$currenttx" ]
do
txid=$(./particl-cli getblock $blockhash | cut -c5- | grep "^\"" | sed 's/"//' | sed 's/"//' | sed 's/,//' | sed -n "$currenttx p")





rawtx=$(./particl-cli getrawtransaction $txid) && decoderaw=$(./particl-cli decoderawtransaction $rawtx | cut -c12- | grep -E ^R | sed 's/"//') 
#Display tx info
echo $decoderaw

#nbmadtxinthistx need to be divided by 4 because 2outputs per MADecrow and 2tx per purchase + verify blind
nbmadtxinthistx=$(echo "rawtx" | wc -l) 

nbmadtot=$(nbmadtxinthistx + nbmadtot)




#####

currenttx=$(($currenttx + 1))
done

#####
currentblock=$(($currentblock + 1)) 
done
