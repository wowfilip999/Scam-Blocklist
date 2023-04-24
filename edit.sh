#!/bin/bash

domains_file="domains"
whitelist_file="whitelist.txt"
blacklist_file="blacklist.txt"
toplist_file="toplist.txt"
github_email="91372088+jarelllama@users.noreply.github.com"
github_name="jarelllama"

function prep_entry {
    read -p $'Enter the new entry (add \'-\' to remove entry):\n' new_entry

    remove_entry=0

    if [[ "$new_entry" == -* ]]; then
        new_entry="${new_entry#-}"
        remove_entry=1
    fi

    new_entry="${new_entry,,}"

    new_entry="${new_entry#*://}"

    new_entry="${new_entry%%/*}"

    if [[ "$new_entry" == www.* ]]; then
        www_subdomain="${new_entry}"
        new_entry="${new_entry#www.}"
    else
        www_subdomain="www.${new_entry}"
    fi

    echo "$new_entry" > tmp_entries.txt

    echo "$www_subdomain" >> tmp_entries.txt
            
    sort tmp_entries.txt -o tmp_entries.txt
}

function edit_blocklist {
    echo "BLOCKLIST"
    
    cp "$domains_file" "$domains_file.bak"

    grep -vE '^(#|$)' "$domains_file" > tmp_domains_file.txt

    prep_entry
            
    if [[ "$remove_entry" -eq 1 ]]; then
        if ! grep -xFqf tmp_entries.txt tmp_domains_file.txt; then
            echo -e "\nDomain not found in blocklist: $new_entry"
            return
        fi

        echo -e "\nDomains removed:"
        comm -12 tmp_domains_file.txt tmp_entries.txt

        comm -23 tmp_domains_file.txt tmp_entries.txt > "$domains_file"

        return
    fi

    if ! [[ "$new_entry" =~ ^[[:alnum:].-]+\.[[:alnum:]]{2,}$ ]]; then
        echo -e "\nInvalid domain. Not added."
        return
    fi

    if grep -xFf tmp_entries.txt "$toplist_file" | grep -vxFqf "$blacklist_file"; then
        echo -e "\nThe domain is found in the toplist. Not added."
        echo "Matches in toplist:"
        grep -xFf tmp_entries.txt  "$toplist_file" | grep -vxFf "$blacklist_file"
        return
    fi

    touch tmp_alive_entries.txt

    while read -r entry; do
        if dig @1.1.1.1 "$entry" | grep -Fq 'NXDOMAIN'; then
            continue
        fi
        echo "$entry" >> tmp_alive_entries.txt
    done < tmp_entries.txt

    if ! [[ -s tmp_alive_entries.txt ]]; then
        echo -e "\nThe domain is dead. Not added."
        return
    fi

    mv tmp_alive_entries.txt tmp_entries.txt
  
    # This checks if there are no unique entries in the new entries file
    if grep -xFqf tmp_entries.txt tmp_domains_file.txt; then
        echo -e "\nThe domain is already in the blocklist. Not added."
        return
    fi        

    echo -e "\nDomains added:"
    comm -23 tmp_entries.txt tmp_domains_file.txt

    cat tmp_entries.txt >> tmp_domains_file.txt 

    sort -u tmp_domains_file.txt -o "$domains_file"
}

function edit_whitelist {
    echo "WHITELIST"

    read -p $'Enter the new entry (add \'-\' to remove entry):\n' new_entry

    new_entry="${new_entry,,}"

    if [[ "$new_entry" == -* ]]; then
        new_entry="${new_entry#-}"
        if ! grep -xFq "$new_entry" "$whitelist_file"; then
            echo -e "\nEntry not found in whitelist: $new_entry"
            return
        fi
        echo -e "\nRemoved from whitelist: $new_entry"
        sed -i "/^$new_entry$/d" "$whitelist_file"
        return
    fi

    # Check if the entry contains whitespaces or is empty
    if [[ "$new_entry" =~ [[:space:]] || -z "$new_entry" ]]; then
        echo -e "\nInvalid entry. Not added."
        return
    fi
    
    if grep -Fq "$new_entry" "$whitelist_file"; then
        existing_entry=$(grep -F "$new_entry" "$whitelist_file" | head -n 1)
        echo -e "\nA similar term is already in the whitelist: $existing_entry"
        return
    fi

    echo -e "\nAdded to whitelist: $new_entry"
    echo "$new_entry" >> "$whitelist_file"

    sort "$whitelist_file" -o "$whitelist_file"
}

function edit_blacklist {
    echo "BLACKLIST"

    prep_entry
            
    if [[ "$remove_entry" -eq 1 ]]; then
        if ! grep -xFqf tmp_entries.txt "$blacklist_file"; then
            echo -e "\nDomain not found in blacklist: $new_entry"
            return
        fi

        echo -e "\nDomains removed:"
        comm -12 "$blacklist_file" tmp_entries.txt

        comm -23 "$blacklist_file" tmp_entries.txt > tmp1.txt

        mv tmp1.txt "$blacklist_file"

        return
    fi

    if ! [[ "$new_entry" =~ ^[[:alnum:].-]+\.[[:alnum:]]{2,}$ ]]; then
        echo -e "\nInvalid domain. Not added."
        return
    fi

    touch tmp_alive_entries.txt

    while read -r entry; do
        if dig @1.1.1.1 "$entry" | grep -Fq 'NXDOMAIN'; then
            continue
        fi
        echo "$entry" >> tmp_alive_entries.txt
    done < tmp_entries.txt

    if ! [[ -s tmp_alive_entries.txt ]]; then
        echo -e "\nThe domain is dead. Not added."
        return
    fi

    mv tmp_alive_entries.txt tmp_entries.txt
  
    # This checks if there are no unique entries in the new entries file
    if grep -xFqf tmp_entries.txt "$blacklist_file"; then
        echo -e "\nThe domain is already in the blacklist. Not added."
        return
    fi

    echo -e "\nDomains added:"
    comm -23 tmp_entries.txt "$blacklist_file"

    cat tmp_entries.txt >> "$blacklist_file" 

    sort -u "$blacklist_file" -o "$blacklist_file"
}

function check_entry {
    read -p $'\nEnter the entry to check:\n' check_entry
    if ! grep -xFq "$check_entry" "$domains_file"; then
        echo -e "\nThe entry is not present."
        if ! grep -Fq "$check_entry" "$domains_file"; then
            return
        fi
        echo "Similar entries:"
        grep -F "$check_entry" "$domains_file"
        return
    fi
    echo -e "\nThe entry is present."
    grep -xFq "$check_entry" "$domains_file"
}

function push_changes {
    echo -e "Push lists changes\n"

    git config user.email "$github_email"
    git config user.name "$github_name"

    git add "$domains_file" "$whitelist_file" "$blacklist_file"
    git commit -m "Update domains"
    git push
}

while true; do
    echo -e "\nEdit Lists Menu:"
    echo "1. Blocklist"
    echo "2. Whitelist"
    echo "3. Blacklist"
    echo "c. Check blocklist entry"
    echo "p. Push lists changes"
    echo "x. Exit/return"
    read choice

    case "$choice" in
        1)
            edit_blocklist
            rm tmp*.txt
            continue
            ;;
        2)
            edit_whitelist
            continue
            ;;
        3)
            edit_blacklist
            rm tmp*.txt
            continue
            ;;
        c)
            check_entry
            continue
            ;;
        p)
            push_changes

            if [[ -f tmp*.txt ]]; then
                rm tmp*.txt
            fi

            exit 0
            ;;
        x)
            if [[ -f tmp*.txt ]]; then
                rm tmp*.txt
            fi

            # Check if the script was sourced by another script
            if [[ "${#BASH_SOURCE[@]}" -gt 1 && "${BASH_SOURCE[0]}" != "${0}" ]]; then
                return
            fi

            exit 0  
            ;;
        *)
            echo -e "\nInvalid option."
            continue  
            ;;
    esac
done
