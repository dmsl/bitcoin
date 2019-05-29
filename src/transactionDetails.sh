#!/bin/bash

#Check if the user gave a file as an argument
if [ $# -eq 0 ]; then
	echo "Please provide a file with a transaction hash in each line"
	exit
#Check if the user gave only one file as an argument
elif [ $# -gt 1 ]; then
	echo "You only have to provide a file with a transaction hash in each line"
	exit
fi

file=$1
lines=$(cat $file)

#Loop through the file with the transactions' hashes
for line in $lines; do
	#request the raw data of a transaction from the website Blockchain.com
	request="curl https://blockchain.info/rawtx/$line"
	$request > tx.txt

	txID="$line"
	#find the blockID to which the particular transaction is stored
	blockID=$(cat tx.txt | tr "," "\n" | grep "\"block_height\"" | tr ":" "\n" | grep -v "block_height")
	
	#if the variable blockID is empty that meand the raw data didn't download
	if [ -z "$blockID" ]; then
		echo "Something went wrong. There are no details for transaction $txID"
		echo "$txID" >> downloadAgain.txt
		continue
	fi
	
	#find the other useful information about the transaction
	version=$(cat tx.txt | tr "," "\n" | grep "\"ver\"" | tr ":" "\n" | grep -v "ver")
	inputCounter=$(cat tx.txt | tr "," "\n" |grep "\"vin_sz\"" | tr ":" "\n" | grep -v "vin_sz")
	outputCounter=$(cat tx.txt | tr "," "\n" |grep "\"vout_sz\"" | tr ":" "\n" | grep -v "vout_sz")
	#the time that a transaction was carried out has to be 
	#converted to the desirable format
	time=$(cat tx.txt | tr "," "\n" |grep "\"time\"" | tr ":" "\n" | grep -v "time")
	txTime=$(TZ=UK date -d  @"$time" +'%Y-%m-%d %H:%M:%S')
	relayed=$(cat tx.txt | tr "," "\n" | grep "\"relayed_by\"" | tr ":" "\n" | grep -v "relayed_by" | tr -d "\"")
	inputAddr=$(cat tx.txt | tr -d "\n " | sed -e 's/\"out\"/\n&/g' | grep -v "\"out\"" | tr "," "\n" |grep "\"addr\"" | tr ":" "\n" | grep -v "addr" | head -"$inputCounter" | tr -d "\"" | tr "\n" "/")
	outputAddr=$(cat tx.txt | tr -d "\n " | sed -e 's/\"out\"/\n&/g' | grep "\"out\"" | tr "," "\n" |grep "\"addr\"" | tr ":" "\n" | grep -v "addr" | tail -"$outputCounter" | tr -d "\"" | tr "\n" "/")
	
	#write all the above transaction info to a CSV file
	echo "$txID,$blockID,$version,$inputCounter,$outputCounter,$txTime,$relayed,$inputAddr,$outputAddr" >> txEntries.csv
	
	#loop through all the inputs of a transaction 
	#and find useful info about each one
	i=0
	while [ $i -lt "$inputCounter" ]; do
		j=$(($i+1))
		prevOutIndex=$(cat tx.txt | tr -d "\n " | sed -e 's/\"out\"/\n&/g' | grep -v "\"out\"" | tr -d "\n " | sed -e 's/\"value\"/\n&/g' | grep "\"value\"" | sed -e 's/\"n\":/\n&/g' | sed -e 's/,\"script\"/\n&/g' | grep "\"n\"" | grep -v "}]" | tr -d "\"n:" | head -"$j" | tail -1)
		inputScript=$(cat tx.txt | tr -d "\n " | sed -e 's/\"script\"/\n&/g' | grep "script" | grep "spent" | head -"$inputCounter" | sed -e 's/,{\"sequence\"/\n&/g' -e 's/],\"weight\"/\n&/g' | grep "script" | tr ":" "\n" | grep -v "script" | tr -d "\"}" | head -"$j" | tail -1)
		inputSequence=$(cat tx.txt | tr -d "\n " | sed -e 's/\"sequence\"/\n&/g' | sed -e 's/\"witness\"/\n&/g' | grep "sequence" | tr ":" "\n" | grep -v "sequence" | tr -d "," | head -"$j" | tail -1)
		
		#write all the above input info to a CSV file
		echo "$txID,$prevOutIndex,$inputScript,$inputSequence" >> inputEntries.csv
		i=$(($i+1))
	done

	#loop through all the outputs of a transaction 
	#and find useful info about each one
	i=0
	while [ $i -lt "$outputCounter" ]; do
		j=$(($i+1))
		outputIndex=$(cat tx.txt | tr -d "\n " | sed -e 's/\"out\"/\n&/g' | grep "\"out\"" | sed -e 's/\"value\"/\n&/g' | grep "\"value\"" | sed -e 's/\"n\":/\n&/g' | sed -e 's/,\"script\"/\n&/g' | grep "\"n\"" | grep -v "]" | tr ":" "\n" | grep -v "n" | head -"$j" | tail -1)
		valueBTC=$(cat tx.txt | tr -d "\n " | sed -e 's/\"out\"/\n&/g' | grep "\"out\"" | sed -e 's/\"value\"/\n&/g' | grep "\"value\"" | sed -e 's/\"n\":/\n&/g' | grep "value" | tr ":" "\n" | tr -d "," | grep -v "value" | head -"$j" | tail -1)
		value=$(bc <<< "scale=10; $valueBTC / 100000000")
		outputScript=$(cat tx.txt | tr -d "\n " | sed -e 's/\"out\"/\n&/g' | grep "\"out\"" | sed -e 's/\"script\"/\n&/g' | tr "}" "\n" | grep "script" | tr ":" "\n" | grep -v "script" | tr -d "\"" | head -"$j" | tail -1)

		#write all the above output info to a CSV file
		echo "$txID,$outputIndex,$value,$outputScript" >> outputEntries.csv
		i=$(($i+1))
	done
done
