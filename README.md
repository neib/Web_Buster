# Web Buster
Search for subdomains, directories, and files for a given URL.</br>
## Requirements
- curl</br>
- bc</br>

`apt install curl bc`</br>
## Usage
./buster.sh -m &lt;mode&gt; -u &lt;URL&gt; -w &lt;wordlist&gt; [--ignore-cert] [-z &lt;milliseconds&gt;] [--no-check] [[--no-slash]]</br>
## Example
./buster.sh -m sub -u https://example.com -w subdomains.list</br>
