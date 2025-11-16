# Web Buster
A Web search tool for subdomains, directories, files, and background information for a given URL.</br>
## Requirements
- <b>curl</b> : command-line tool for transferring data using URL syntax</br>
- <b>bc</b> : bc GNU arbitrary precision calculator language</br>
- <b>jq</b> : lightweight and flexible command-line JSON processor</br>
- <b>searchsploit</b> : searching for exploits and vulnerabilities in the local Exploit-DB database (include in exploitdb package from Kali Linux)</br>
<!-- `apt install curl bc jq exploitdb`</br> -->
## Usage
`./buster.sh -m &lt;mode&gt; -u &lt;URL&gt; [-w &lt;wordlist&gt; [-i] [-z <milliseconds>] [-nc] [-f] [-p] [-A] [-v] [[-nC]] [[-ns]] [[-r]] [-P] [[-I]]]`</br>
</br>
<b>Examples</b></br>
`./buster.sh -m sub -u https://example.com`</br>
`./buster.sh -m dir -u https://example.com/ -w directories.list`</br>
`./buster.sh -m file -u https://example.com/dir/ -w files.list`</br>
`./buster.sh -m wap -u https://example.com`</br>
</br>
## Help
<b>Arguments:</b></br>
&nbsp;&nbsp;<b>-h, --help</b>&nbsp;&nbsp;                                  <i>Print this help.</i></br>
&nbsp;&nbsp;<b>-m, --mode &lt;mode&gt;</b>&nbsp;&nbsp;                    <i>Specify what to search for. The mode can be : sub (Subdomain discovery), dir (Directory discovery), file (File discovery), wap (Background information).</i></br>
&nbsp;&nbsp;<b>-u, --url &lt;url&gt;</b>&nbsp;&nbsp;                       <i>Specify a target.</i></br>
&nbsp;&nbsp;<b>-w, --wordlist &lt;wordlist&gt;</b>&nbsp;&nbsp;        <i>Specify a dictionnary to use Optional for Subdomain discovery) (Do not use with Background information).</i></br>
</br>
<b>Optional:</b></br>
&nbsp;&nbsp;<b>-i, --ignore-cert</b>&nbsp;&nbsp;                               <i>Perform 'insecure' SSL connection.</i></br>
&nbsp;&nbsp;<b>-z, --timer &lt;milliseconds&gt;</b>&nbsp;&nbsp;   <i>Waiting between requests.</i></br>
&nbsp;&nbsp;<b>-nc, --no-check</b>&nbsp;&nbsp;                                  <i>Do not attempt to contact the site initially.</i></br>
&nbsp;&nbsp;<b>-f, --follow</b>&nbsp;&nbsp;                                <i>Follow redirects.</i></br>
&nbsp;&nbsp;<b>-p, --proxy &lt;[protocol://]host[:port]&gt;</b>&nbsp;&nbsp;      <i>Use this proxy.</i></br>
&nbsp;&nbsp;<b>-A, --user-agent '&lt;user-agent&gt;'</b>&nbsp;&nbsp;             <i>Custom User Agent.</i></br>
&nbsp;&nbsp;<b>-v, --verbose</b>&nbsp;&nbsp;                               <i>Verbose mode.</i></br>
&nbsp;&nbsp;<b>-nC, --no-crt</b>&nbsp;&nbsp;                                    <i>Do not check information from crt.sh|Certificate Search (Subdomain discovery only).</i></br>
&nbsp;&nbsp;<b>-ns, --no-slash</b>&nbsp;&nbsp;                                  <i>Do not add a final '/' to the directory name (Directory discovery only).</i></br>
&nbsp;&nbsp;<b>-r, --recursive</b>&nbsp;&nbsp;                             <i>Recursive search (Subdomain and Directory discovery only).</i></br>
&nbsp;&nbsp;<b>-P, --max-parallel &lt;max-parallel&gt;</b>&nbsp;&nbsp;           <i>Multiprocessing (Do not use with Background information).</i></br>
&nbsp;&nbsp;<b>-I, --inhaler</b>&nbsp;&nbsp;                               <i>Additional search for links (Background information only)</i></br>
</br>
<b>Examples:</b></br>
&nbsp;&nbsp;<i>`./buster.sh -m sub -u http://domain.com -w subdomains.list`</i></br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* Subdomain discovery for 'http://domain.com' using the wordlist 'subdomains.list'.</br></br>
&nbsp;&nbsp;<i>`./buster.sh --mode dir -u https://other.domain.com/somedire/ -w directories.list --ignore-cert`</i></br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* Directory discovery for 'https://other.domain.com/somedire/' using the wordlist 'directories.list' and ignoring secutity certificates.</br></br>
&nbsp;&nbsp;<i>`./buster.sh -m file -u https://www.another.com/files -w files.list --ignore-cert -z 200`</i></br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* File discovery for 'https://www.another.com/files/' using the wordlist 'files.list' with a delay of 0.2s and ignoring secutity certificates.</br></br>
&nbsp;&nbsp;<i>`./buster.sh -m dir -u https://againandagain.com/ -w directories.list --no-check --no-slash --verbose`</i></br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* Directory discovery for 'https://againandagain.com/' using the wordlist 'directories.list'. Does not check if the target is up, does not add a final '/' to the directory name and display the currently tested directory.</br></br>
&nbsp;&nbsp;<i>`./buster.sh --mode sub -u https://againagainagain.com`</i></br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* Subdomain discovery for 'https://gainagainagain.com' using only Certificate Transparency logs.</br></br>
&nbsp;&nbsp;<i>`./buster.sh --mode wap -u https://otherone.com -f`</i></br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* Background information for 'https://otherone.com' following redirects</br></br>
## Notes
The subdomains module is partly inspired by this project: https://github.com/UnaPibaGeek/ctfr</br>
It just look for Certificate Transparency Logs at: https://crt.sh/</br>
Of course, you can use a dictionary attack to combine with CTL for subdomains enumeration.</br>
