# Scam Blocklist

| Syntax | Entries |
| --- |:---:|
| [Adblock Plus](https://raw.githubusercontent.com/jarelllama/Scam-Blocklist/main/adblock.txt) | 2535 |
| [Domains](https://raw.githubusercontent.com/jarelllama/Scam-Blocklist/main/domains.txt) | 5044 |

```
Unique scam sites found:
Today: 161
Yesterday: 39
Total: 2535

Updated: Fri Apr 28 17:35 UTC
```

### How domains are added to the blocklist

- The script searches Google with a list of search terms almost exclusively used in scam sites
- Domains are filtered against a whitelist (scam reporting sites, forums, genuine stores, etc.), along with other filtering
- Domains are compared against the Cisco Umbrella Toplist
- Domains found in the toplist are checked manually
- Dead domains are removed
- Resolving `www` subdomains are included in the domains list
- Domains that are found in toplist/whitelist updates are vetted manually

Malicious domains found in [r/Scams](https://www.reddit.com/r/Scams) are also added after being manually vetted.

To see the full filtering process check out the code in the repository.

### Inspiration

After browsing r/Scams for weeks and manually reporting scam sites to Hagezi's issue tracker, I realised most scam sites follow a similar template.

There is no way I can keep up with the number of scam sites created daily but with this project, I aim to retrieve as many newly created scam sites as possible.

### See also

[Durablenapkin's Scam Blocklist](https://github.com/durablenapkin/scamblocklist)

[Hagezi's Fake list](https://github.com/hagezi/dns-blocklists#fake) (Contains both my list and Durablenapkin's list)

### Top scam TLDs

| TLD | Count |
| ---:|:--- |
| com  | 3406 |
| shop  | 613 |
| store  | 353 |
| online  | 76 |
| net  | 68 |
| xyz  | 64 |
| space  | 60 |
| us  | 46 |
| website  | 38 |
| co  | 35 |
