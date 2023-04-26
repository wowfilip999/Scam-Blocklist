#!/bin/bash

readme="README.md"
template="data/README.md.template"
domains_file="domains.txt"
adblock_file="adblock.txt"

adblock_count=$(grep -vE '^(!|$)' "$adblock_file" | wc -l)

domains_count=$(grep -vE '^(#|$)' "$domains_file" | wc -l)

sed -i 's/adblock_count/'"$adblock_count"'/g' "$template"

sed -i 's/domains_count/'"$domains_count"'/g' "$template"

if diff -q "$readme" "$template" >/dev/null; then
   echo -e "\nNo changes. Exiting...\n"
   exit 0
fi

sed -i 's/update_time/'"$(date -u +"%a %b %d %H:%M UTC")"'/g' "$template"

top_tlds=$(awk -F '.' '{print $NF}' data/raw.txt | sort | uniq -c | sort -nr | head -15 | awk '{print "| " $2, " | "$1 " |"}')

awk -v var="$top_tlds" '{gsub(/top_tlds/,var)}1' "$template" > "$readme"

# Note that only the README file should be pushed
