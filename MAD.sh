block=518023
#we should start at 0 but madescrow in this block (518023)

cd
cd particlcore

#need a big loop block++ until we reach the last one
blockhash=$(./particl-cli getblockstats $block | grep blockhash | sed 's/.* //' | sed 's/"//' | sed 's/"//' | sed 's/,//')

# need small loop: sed 1p, sed 2p, sed 3p... for each tx in the block
txid=$( ./particl-cli getblock $blockhash | cut -c5- | grep "^\"" | sed 's/"//' | sed 's/"//' | sed 's/,//' | sed -n "1p")

rawtx=$(./particl-cli getrawtransaction $txid) && decoderaw=$(./particl-cli decoderawtransaction $rawtx | cut -c12- | grep -E ^P | sed 's/"//') 
#Display tx info
echo $decoderaw

#nbmaxtxinthistx need to be divided by 4 because 2outputs per MADecrow and 2tx per purchase + verify blind
nbmadtxintheblock=$(echo "rawtx" | wc -l) 

nbmadtot=$(nbmadtxinthistx + nbmadtot)
