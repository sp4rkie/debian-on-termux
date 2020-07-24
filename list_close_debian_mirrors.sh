#!/bin/bash

#
# list_close_debian_mirrors.sh 
#

simpleping(){
	URL="$1"
	D="$(echo "$URL" \
		| perl -pe 's/.*\/\///g;s/\/.*//g')"
	{
	ping -c 1 -W 1 "$D" \
		| grep "time=" \
		| perl -pe 's/.*time=//g;s/\n/\t/g'
	echo "$URL"
	} | grep .
}
export -f simpleping

curl -s https://www.debian.org/mirror/list \
	| grep http \
	| grep "debian/</a>" \
	| perl -pe 's/.*"(http)/$1/g;s/".*//g' \
	| xargs -I {} -P 99 bash -c "simpleping '{}'" \
	| grep " ms" \
	| sort -n \
	| head
