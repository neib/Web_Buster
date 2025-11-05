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
</br>
## Help
<b>Arguments:</b></br>
&nbsp;&nbsp;-h, --help                                  Print this help.</br>
&nbsp;&nbsp;-m &lt;mode&gt;, --mode &lt;mode&gt;                    Specify what to search for. The mode can be : sub (subdomain discovery), dir (directory discovery), file (file discovery).</br>
&nbsp;&nbsp;-u &lt;url&gt;, --url &lt;url&gt;                       Specify a target.</br>
&nbsp;&nbsp;-w &lt;wordlist&gt;, --wordlist &lt;wordlist&gt;        Specify a dictionnary to use.</br>
</br>
<b>Optional:</b></br>
&nbsp;&nbsp;-i, --ignore-cert                               Perform 'insecure' SSL connection.</br>
&nbsp;&nbsp;-z &lt;milliseconds&gt;, --timer &lt;milliseconds&gt;   Waiting between requests.</br>
&nbsp;&nbsp;-nc, --no-check                                  Do not attempt to contact the site initially.</br>
&nbsp;&nbsp;-v, --verbose                               Verbose mode.</br>
</br>
<b>Mode sub only:</b></br>
&nbsp;&nbsp;-nC, --no-crt                                    Do not check information from crt.sh|Certificate Search.</br>
&nbsp;&nbsp;-c, --crt-only                              Do not perform a dictionary attack. Cannot be used with -w|--wordlist</br>
</br>
<b>Mode dir only:</b></br>
&nbsp;&nbsp;-ns, --no-slash                                  Do not add a final '/' to the directory name.</br>
</br>
<b>Examples:</b></br>
&nbsp;&nbsp;./buster.sh -m sub -u http://domain.com -w subdomains.list</br>
&nbsp;&nbsp;./buster.sh --mode dir -u https://other.domain.com/somedire/ -w directories.list --ignore-cert</br>
&nbsp;&nbsp;./buster.sh -m file -u https://www.another.com/files -w files.list --ignore-cert -z 200</br>
&nbsp;&nbsp;./buster.sh -m dir -u https://againandagain.com/ -w directories.list --no-check --no-slash --verbose</br>
&nbsp;&nbsp;./buster.sh --mode sub -u https://againagainagain.com -c</br>
</br>
## Notes
The subdomains module is partly inspired by this project: https://github.com/UnaPibaGeek/ctfr</br>
It just look for Certificate Transparency Logs at: https://crt.sh/</br>
Of course, you can use a dictionary attack for subdomains enumeration.</br>
