#!/bin/bash

# Define input and output file paths
domains_file="domains.txt"           # The file containing the domains to filter
whitelist_file="whitelist.txt"     # The file containing whitelisted domains
blacklist_file="blacklist.txt"     # The file containing blacklisted domains
toplist_file="toplist.txt"         # The file containing the list of top domains
new_domains_file="new_domains.txt" # The file containing new domains to be added

# Define a temporary file for storing the live domains
temp_file=$(mktemp)

# Initialize counters for the number of removed and added domains
removed_domains=0
added_domains=0

# Add new domains to the input file if they are not already in the file
if [ -f "$new_domains_file" ]; then
  while read -r new_domain; do
    if ! grep -qFx "$new_domain" "$domains_file"; then
      echo "$new_domain" >> "$domains_file"
      added_domains=$((added_domains+1))
    fi
  done < "$new_domains_file"
fi

# Print the total number of newly added domains before filtering
echo "Total number of new domains before filtering: $added_domains"

# Remove any empty lines from the input file
sed -i '/^$/d' "$domains_file"

# Loop over each line in the input file
while read -r domain; do
  # Check if the domain or any of its subdomains appear in the whitelist
  if grep -qFf "$whitelist_file" <(echo "$domain"); then
    echo "Domain removed: $domain (whitelisted)"
    removed_domains=$((removed_domains+1))
  # Check if the domain is already in the temporary file
  elif grep -qFx "$domain" "$temp_file"; then
    echo "Domain removed: $domain (duplicate)"
    removed_domains=$((removed_domains+1))
  # Check if the domain is dead
  elif dig @1.1.1.1 "$domain" | grep -q 'NXDOMAIN'; then
    echo "Domain removed: $domain (dead)"
    removed_domains=$((removed_domains+1))
  else
    echo "$domain" >> "$temp_file"
  fi
done < "$domains_file"

# Copy the temporary file to the input file
cp "$temp_file" "$domains_file"

# Sort the input file and overwrite it
sort -o "$domains_file" "$domains_file"

# Print the total number of removed domains
echo "Total number of domains removed: $removed_domains"

# Find the common domains between domains.txt and toplist.txt, excluding domains in blacklist.txt
echo "Domains in toplist:"
comm -12 <(sort "$input_file") <(sort "$toplist_file") | grep -vFxf "$blacklist_file"

# Remove the temporary file
rm "$temp_file"
