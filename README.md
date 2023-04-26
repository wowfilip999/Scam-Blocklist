# Scam Blocklist

| Syntax | Domains/Entries |
| --- |:---:|
| [Adblock Plus](https://raw.githubusercontent.com/jarelllama/Scam-Blocklist/main/adblock.txt) | 2353 |
| [Domains](https://raw.githubusercontent.com/jarelllama/Scam-Blocklist/main/domains.txt) | 4684 |

Updated: Wed Apr 26 16:40 UTC

### How domains are added to the blocklist

- The script searches Google with a list of search terms almost exclusively used in scam sites
- Invalid entries (non domains) are removed
- Domains are filtered against a whitelist (scam reporting sites, forums, genuine stores, etc.)
- Domains with whitelisted TLDs (edu, gov) are removed
- Domains are compared against the Cisco Umbrella Toplist
- Domains found in the toplist are checked manually
- Dead domains are removed
- Resolving `www` subdomains are included in the domains list
- Domains that are found in toplist/whitelist updates are vetted manually

Malicious domains found in [r/Scams](https://www.reddit.com/r/Scams) are also added after being manually vetted.

### Goal

Identify newly created scam sites that use the same template as reported scam sites.

### See also

[Durablenapkin's Scam Blocklist](https://github.com/durablenapkin/scamblocklist)

[Hagezi's Fake list](https://github.com/hagezi/dns-blocklists#fake) (Contains both my list and Durablenapkin's list)

### Top scam TLDs

| TLD | Count |
| ---:|:--- |
| com  | 3160 |
| shop  | 558 |
| store  | 337 |
| online  | 74 |
| net  | 62 |
| xyz  | 59 |
| space  | 56 |
| us  | 42 |
| website  | 38 |
| top  | 34 |
