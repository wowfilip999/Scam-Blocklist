#!/bin/bash

raw_file="data/raw.txt"
optimised_entries="data/optimised_entries.txt"
optimiser_whitelist="data/optimiser_whitelist.txt"

trap "find . -maxdepth 1 -type f -name '*.tmp' -delete" exit

while true; do
    grep -E '\..*\.' data/raw.txt \
        | cut -d '.' -f2- \
        | awk -F '.' '$1 ~ /.{4,}/ {print}' \
        | sort \
        | uniq -d > 1.tmp
    
    comm -23 1.tmp "$optimiser_whitelist" > 2.tmp
    comm -23 2.tmp "$optimised_entries" > 3.tmp
    comm -23 3.tmp "$raw_file" > domains.tmp

    if ! [[ -s domains.tmp ]]; then
        echo -e "\nNo potential optimizations found.\n"
    else
        numbered_domains=$(cat domains.tmp | awk '{print NR ". " $0}')
        echo -e "\nPotential optimisations:"
        echo "${numbered_domains}"

        echo -e "\nEnter 'a' to add all domains to the blocklist."
        echo "Enter a domain number to add it to the whitelist."
    fi
    echo "Enter 'p' to push changes."
    echo "Enter 'x' to exit."
    read -r choice

    [[ "$choice" == 'x' ]] && exit 0
    
    if [[ "$choice" == 'p' ]]; then
        echo -e "\nPushing changes..."
        git add "$raw_file" "$optimised_entries" "$optimiser_whitelist"
        git commit -m "Optimise blocklist"
        git push
        exit 0
    fi
    
    if [[ $choice == 'a' ]]; then
        cat domains.tmp >> "$raw_file"
        cat domains.tmp >> "$optimised_entries"
        sort "$raw_file" -o "$raw_file"
        sort "$optimised_entries" -o "$optimised_entries"
    else
        chosen_domain=$(echo "$numbered_domains" | awk -v n="$chosen_number" '$1 == n {print $2}')
        echo -e "\nAdded '${chosen_domain}' to the whitelist."
        echo "$chosen_domain" >> "$optimiser_whitelist"
        sort "$optimiser_whitelist" -o "$optimiser_whitelist"
    fi
done
