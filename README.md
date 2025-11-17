# WebBuster
A Web search tool for subdomains, directories, files, and background information for a given URL.</br>
## Requirements
- <b>curl</b> : command-line tool for transferring data using URL syntax</br>
- <b>bc</b> : bc GNU arbitrary precision calculator language</br>
- <b>jq</b> : lightweight and flexible command-line JSON processor</br>
```
apt install curl bc jq
```
- <b>searchsploit</b> : searching for exploits and vulnerabilities in the local Exploit-DB database</br>
https://gitlab.com/exploit-database/exploitdb</br>
```
git clone https://gitlab.com/exploit-database/exploitdb.git /opt/exploitdb
ln -sf /opt/exploitdb/searchsploit /usr/local/bin/searchsploit
```
## Usage
```
./buster -m <mode> -u <URL> [options]
```
## Examples
```
./buster --help
./buster -m sub -u https://example.com
./buster -m dir -u https://example.com/ -w directories.list
./buster -m file -u https://example.com/dir/ -w files.list
./buster -m scav -u https://example.com -a
./buster -m crawl -u https://example.com -z 200
```
## Help
```
            __        __   _     ____            _                       
---+++===[  \ \      / /__| |__ | __ ) _   _ ___| |_ ___ _ __            
             \ \ /\ / / _ \ '_ \|  _ \| | | / __| __/ _ \ '__|           
              \ V  V /  __/ |_) | |_) | |_| \__ \ ||  __/ |              
               \_/\_/ \___|_.__/|____/ \__,_|___/\__\___|_|    ]===+++---

      A Web search tool for subdomains, directories, files and background information.          



  Usage: ./buster -m <mode> -u <URL> [options]

Common arguments :
  -h, --help                                                  Display this help
  -m, --mode <mode>                                           Buster mode
  -u, --url <URL>                                             Target URL

Available modes :
  sub    : Subdomain Buster           (Subdomain discovery)
  dir    : Directory Buster           (Directory discovery)
  file   : File Buster                (File discovery)
  scav   : Background Buster          (Background discovery)
  crawl  : Sitemap Buster             (Sitemap discovery)



 * Sub mode (Subdomain discovery) :
    This mode will retrieve the list of subdomains of the target based on Certificates Transparency Logs or by dictionary enumeration.

  Required     : -u, --url <URL>                              Target URL

  Optional     : -w, --wordlist <file>                        Dictionary to use
                 -i, --ignore-cert                            'Insecure' SSL connection
                 -z, --timer <millisecondes>                  Wait time between requests
                 -nc, --no-check                              Do not test the site initially
                 -p, --proxy <[protocol://]host[:port]>       Use proxy
                 -c, --cookie <key=value[;key=value]>         Use cookies
                 -A, --user-agent <user-agent>                Custom User Agent
                 -v, --verbose                                Verbose mode
                 -nC, --no-crt (use with --wordlist)          Do not check Certificate Transparency Logs (crt.sh)
                 -f, --follow                                 Follow redirects
                 -P, --max-parallel <max-parallel>            Multiprocessing
                 -I, --inhaler                                Additional search for links

  Exemple      : ./buster --mode sub --url https://example.com



 * Dir mode (Directory discovery) :
    This mode will attempt to list all directories and subdirectories of a target based on a dictionary enumeration.

  Required     : -u, --url <URL>                              Target URL
                 -w, --wordlist <file>                        Dictionary to use

  Optional     : -i, --ignore-cert                            'Insecure' SSL connection
                 -z, --timer <millisecondes>                  Wait time between requests
                 -nc, --no-check                              Do not test the site initially
                 -p, --proxy <[protocol://]host[:port]>       Use proxy
                 -c, --cookie <key=value[;key=value]>         Use cookies
                 -A, --user-agent <user-agent>                Custom User Agent
                 -v, --verbose                                Verbose mode
                 -f, --follow                                 Follow redirects
                 -P, --max-parallel <max-parallel>            Multiprocessing
                 -ns, --no-slash                              Do not add a final '/' to the directory name
                 -r, --recursive                              Recursive search

  Exemple      : ./buster --mode dir --url https://example.com --wordlist words.txt --verbose



 * File mode (File discovery) :
    This mode will attempt to list all files on a target based on a dictionary enumeration.

  Required     : -u, --url <URL>                              Target URL
                 -w, --wordlist <file>                        Dictionary to use

  Optional     : -i, --ignore-cert                            'Insecure' SSL connection
                 -z, --timer <millisecondes>                  Wait time between requests
                 -nc, --no-check                              Do not test the site initially
                 -p, --proxy <[protocol://]host[:port]>       Use proxy
                 -c, --cookie <key=value[;key=value]>         Use cookies
                 -A, --user-agent <user-agent>                Custom User Agent
                 -v, --verbose                                Verbose mode
                 -f, --follow                                 Follow redirects
                 -P, --max-parallel <max-parallel>            Multiprocessing

  Exemple      : ./buster --mode file --url https://example.com --wordlist words.txt -z 200



 * Scav mode (Background information) :
    This mode will attempt to understand the target's architecture.

  Required     : -u, --url <URL>                              Target URL

  Optional     : -i, --ignore-cert                            'Insecure' SSL connection
                 -z, --timer <millisecondes>                  Wait time between requests
                 -nc, --no-check                              Do not test the site initially
                 -p, --proxy <[protocol://]host[:port]>       Use proxy
                 -c, --cookie <key=value[;key=value]>         Use cookies
                 -A, --user-agent <user-agent>                Custom User Agent
                 -v, --verbose                                Verbose mode
                 -f, --follow                                 Follow redirects
                 -I, --inhaler                                Additional search for links
                 -a, --agressive                              More aggressive, more requests

  Exemple      : ./buster --mode scav --url https://example.com -a



 * Crawl mode (Homemade sitemap) :
    This mode will retrieve all internal links accessible from the given URL to build the target tree structure.

  Required     : -u, --url <URL>                              Target URL

  Optional     : -i, --ignore-cert                            'Insecure' SSL connection
                 -z, --timer <millisecondes>                  Wait time between requests
                 -nc, --no-check                              Do not test the site initially
                 -p, --proxy <[protocol://]host[:port]>       Use proxy
                 -c, --cookie <key=value[;key=value]>         Use cookies
                 -A, --user-agent <user-agent>                Custom User Agent
                 -v, --verbose                                Verbose mode
                 -f, --follow                                 Follow redirects
                 -P, --max-parallel <max-parallel>            Multiprocessing

  Exemple      : ./buster --mode crawl --url https://example.com -f -i

```
## Notes
* Subdomain mode will check the Certificate Transparency Logs available at this address: https://crt.sh/
* Files and Directory modes typically perform dictionary-based enumeration.
* Scavenger mode will attempt to capture as much information as possible about a given target. By default, it will only perform one query, but it can be used more aggressively (many requests).
* Crawler mode will attempt to reconstruct the tree structure based solely on what is accessible from the source page for a given target.
</br>
The subdomain mode is partly inspired by this project: https://github.com/UnaPibaGeek/ctfr</br>

