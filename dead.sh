#!/bin/bash
raw_file='data/raw.txt'
adblock_file='lists/adblock/scams.txt'
domain_log='data/domain_log.csv'
root_domains_file='data/processing/root_domains.txt'
subdomains_file='data/processing/subdomains.txt'
subdomains_to_remove_file='config/subdomains.txt'
wildcards_file='data/processing/wildcards.txt'
redundant_domains_file='data/processing/redundant_domains.txt'
dead_domains_file='data/processing/dead_domains.txt'
time_format="$(TZ=Asia/Singapore date +"%H:%M:%S %d-%m-%y")"

function main {
    npm i -g @adguard/dead-domains-linter  # Install AdGuard Dead Domains Linter
    for file in config/* data/*; do  # Format files in the config and data directory
        format_list "$file"
    done
    check_alive
    check_subdomains
    check_redundant
    check_dead
    check_line_count
}   

function check_alive {
    sed 's/^/||/; s/$/^/' "$dead_domains_file" > formatted_dead_domains_file.tmp  # Format dead domains file
    dead-domains-linter -i formatted_dead_domains_file.tmp --export dead.tmp  # Find dead domains in the dead domains file
    alive_domains=$(comm -23 "$dead_domains_file" dead.tmp) # Find resurrected domains in the dead domains file
    if [[ -z "$alive_domains" ]]; then
        rm dead.tmp
        return  # Return early if no alive domains found
    fi
    cp dead.tmp "$dead_domains_file"  # Update dead domains file to include only dead domains
    rm dead.tmp
    printf "%s\n" "$alive_domains" >> "$raw_file"  # Add resurrected domains to the raw file
    format_list "$raw_file"
    log_event "$alive_domains" "resurrected" "dead_domains_file"
}

function check_subdomains {
    sed 's/^/||/; s/$/^/' "$subdomains_file" > formatted_subdomains_file.tmp # Format subdomains file
    dead-domains-linter -i formatted_subdomains_file.tmp --export dead.tmp  # Find and export dead domains with subdomains
    if [[ ! -s dead.tmp ]]; then
        rm dead.tmp
        return  # Return if no dead domains found
    fi
    # Remove dead subdomains from domains with subdomains file
    comm -23 "$subdomains_file" dead.tmp > subdomains.tmp && mv subdomains.tmp "$subdomains_file"
    while read -r subdomain; do  # Loop through common subdomains
        sed "s/^${subdomain}\.//" dead.tmp >> collated_dead_root_domains.tmp  # Strip to root domains and collate into file
    done < "$subdomains_to_remove_file"
    rm dead.tmp
    sort -u collated_dead_root_domains.tmp -o collated_dead_root_domains.tmp
    # Remove dead root domains from raw file and root domains file
    comm -23 "$raw_file" collated_dead_root_domains.tmp > raw.tmp && mv raw.tmp "$raw_file"
    comm -23 "$root_domains_file" collated_dead_root_domains.tmp > root.tmp && mv root.tmp "$root_domains_file"
    cat collated_dead_root_domains.tmp >> "$dead_domains_file"  # Collate dead domains
    format_list "$dead_domains_file"
    log_event "$(<collated_dead_root_domains.tmp)" "dead" "raw"
}

function check_redundant {
    sed 's/^/||/; s/$/^/' "$redundant_domains_file" > formatted_redundant_domains_file.tmp # Format redundant domains file
    dead-domains-linter -i formatted_redundant_domains_file.tmp --export dead.tmp  # Find and export dead redundant domains
    if [[ ! -s dead.tmp ]]; then
        rm dead.tmp
        return  # Return if no dead domains found
    fi
    # Remove dead redundant domains from redundant domains file
    comm -23 "$redundant_domains_file" dead.tmp > redundant.tmp && mv redundant.tmp "$redundant_domains_file"
    rm dead.tmp
    while read -r wildcard; do  # Loop through wildcard domains
        redundant_domains=$(grep "\.${wildcard}$" "$redundant_domains_file")  # Find redundant domains remaining in the redundant domains file
        [[ -n "$redundant_domains" ]] && continue  # Skip to next wildcard if not all matches are dead
        printf "%s\n" "$wildcard" >> collated_dead_wildcards.tmp  # Collate unused wildcard domains
    done < "$wildcards_file"
    sort -u collated_dead_wildcards.tmp -o collated_dead_wildcards.tmp
    # Remove unused wildcard domains from raw file and wildcards file
    comm -23 "$raw_file" collated_dead_wildcards.tmp > raw.tmp && mv raw.tmp "$raw_file"
    comm -23 "$wildcards_file" collated_dead_wildcards.tmp > wildcards.tmp && mv wildcards.tmp "$wildcards_file"
    cat collated_dead_wildcards.tmp >> "$dead_domains_file"  # Collate dead domains
    format_list "$dead_domains_file"
    log_event "$(<collated_dead_wildcards.tmp)" "dead" "wildcard"
}

function check_dead {
    dead-domains-linter -i "$adblock_file" --export dead.tmp  # Find and export dead domains
    dead_domains=$(comm -23 dead.tmp "$root_domains_file")  # Exclude subdomains stripped to root domains
    dead_domains=$(comm -23 <(printf "%s" "$dead_domains" "$wildcards_file"))  # Exclude wildcard domains
    rm dead.tmp
    [[ -z "$dead_domains" ]] && return  # Return if no dead domains found
    # Remove dead domains from raw file
    comm -23 "$raw_file" <(printf "%s" "$dead_domains") > raw.tmp && mv raw.tmp "$raw_file"
    printf "%s\n" "$dead_domains" >> "$dead_domains_file"  # Collate dead domains
    format_list "$dead_domains_file"
    log_event "$dead_domains" "dead" "raw"
}

function check_line_count {
    # Check if the dead domains file has more than 5000 lines
    dead_domains_count=$(wc -w < "$dead_domains_file")
    if [[ dead_domains_count -gt 5000 ]]; then
        # Clear first 1000 lines
        tail +1001 "$dead_domains_file" > dead.tmp && mv dead.tmp "$dead_domains_file"
    fi
}

function log_event {
    # Log domain processing events
    printf "%s" "$1" | awk -v type="$2" -v source="$3" -v time="$time_format" '{print time "," type "," $0 "," source}' >> "$domain_log"
}

function format_list {
    [[ -f "$1" ]] || return  # Return if file does not exist
    # If file is a CSV file, do not sort
    if [[ "$1" == *.csv ]]; then
        sed -i 's/\r$//' "$1"  
        return
    fi
    # Remove whitespaces, carriage return characters, empty lines, sort and remove duplicates
    tr -d ' \r' < "$1" | tr -s '\n' | sort -u > "${1}.tmp" && mv "${1}.tmp" "$1"
}

function cleanup {
    find . -maxdepth 1 -type f -name "*.tmp" -delete
}

trap cleanup EXIT
main

