#!/bin/bash

#Check if the user gave a block hash as an argument
if [ $# -eq 0 ]; then
	echo "Please provide a Bitcoin block hash"
	exit
#Check if the user gave only one block hash as an argument
elif [ $# -gt 1 ]; then
	echo "You only have to provide a Bitcoin block hash"
	exit
fi

BLOCKHASH=$1
i=0

#Loop for N=15000 times
while [ $i -lt 15000 ]; do
	#Request the raw block data from the website Blockchain.com
	REQUEST="curl https://blockchain.info/rawblock/$BLOCKHASH"
	$REQUEST > block.txt
	
	#Find the height of the block
	BLOCKID=$(cat block.txt | tr "," "\n" | grep "\"height\"" | tr ":" "\n" | grep -v "height")
	
	#if the variable blockID is empty then it means that the 
	#raw data didn't download and the script stops. The user 
	#has to start the script again from the block that it stopped
	if [ -z "$BLOCKID" ]; then
		echo "Something went wrong. There are no details for block $BLOCKHASH"
		echo "Next time start from block $BLOCKHASH"
		exit
	fi

	#Collect other useful information about the particular block
	SIZEBYTES=$(cat block.txt | tr "," "\n" | grep "\"size\"" | tr ":" "\n" | grep -v "size" | head -1)
	TEMP1=$(bc <<< "scale=3; $SIZEBYTES / 1000")
	if [[ $TEMP1 == \.* ]]; then
		SIZEKB="0$TEMP1"
	else
		SIZEKB="$TEMP1"
	fi
	BLOCKSIZE="$SIZEKB kB"
	BLOCKVERSION=$(cat block.txt | tr "," "\n" | grep "\"ver\"" | tr ":" "\n" | grep -v "ver" | head -1)
	PREVBLOCKHASH=$(cat block.txt | tr "," "\n" | grep "\"prev_block\"" | tr ":" "\n" | grep -v "prev" | tr -d "\"")
	MERKLEROOT=$(cat block.txt | tr "," "\n" | grep "\"mrkl_root\"" | tr ":" "\n" | grep -v "root" | tr -d "\"")
	#The time of the block creation must be converted in the 
	#desirable format
	BLOCKTIME=$(cat block.txt | tr "," "\n" | grep "\"time\"" | tr ":" "\n" | grep -v "time" | tr -d "\"" | head -1)
	BLOCKDATETIME=$(TZ=UK date -d  @"$BLOCKTIME" +'%Y-%m-%d %H:%M:%S')
	BITS=$(cat block.txt | tr "," "\n" | grep "\"bits\"" | tr ":" "\n" | grep -v "bits")
	TEMP=$(cat block.txt | tr "," "\n" | grep "\"nonce\"" | tr ":" "\n" | grep -v "nonce")
	if [[ $TEMP -lt "0" ]]; then
		NONCE=$((4294967296+$TEMP))
	else
		NONCE="$TEMP"
	fi
	TXCOUNTER=$(cat block.txt | tr "," "\n" | grep "\"n_tx\"" | tr ":" "\n" | grep -v "tx")

	#Write all the above block details into a CSV file
	echo "$BLOCKID,$BLOCKSIZE,$BLOCKVERSION,$PREVBLOCKHASH,$MERKLEROOT,$BLOCKDATETIME,$BITS,$NONCE,$TXCOUNTER,$BLOCKHASH" >> blockEntries.csv

	#Write the transaction hashes of the particular block 
	#into a text file to use it later to get the transaction details
	cat block.txt | tr "," "\n" | grep "\"hash\"" | tail -n +2 | tr ":" "\n" | grep -v "hash" | grep -v "tx" | tr -d "\"" >> transactions.txt
	
	#Find the hash value of the next block in order to get 
	#its raw data
	BLOCKHASH=$(cat block.txt | tr "," "\n" | grep "\"next_block\"" | tr ":" "\n" | grep -v "next" | tr -d "[\"" | tr -d "\"]")
	i=$(($i+1))
done
echo "Next time start from block $BLOCKHASH"


