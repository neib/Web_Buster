# Web Buster
A Web search tool for subdomains, directories, and files for a given URL.</br>
## Requirements
- curl : command-line tool for transferring data using URL syntax</br>
- bc : bc GNU arbitrary precision calculator language</br>
- jq : lightweight and flexible command-line JSON processor</br>

`apt install curl bc jq`</br>
## Usage
./buster.sh -m &lt;mode&gt; -u &lt;URL&gt; -w &lt;wordlist&gt; [--ignore-cert] [-z &lt;milliseconds&gt;] [--no-check] [[--no-slash]] [-v]</br>
## Example
./buster.sh -m sub -u https://example.com -w subdomains.list</br>
