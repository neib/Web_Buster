#!/bin/bash

# Search for subdomains, directories, files and background information for a given URL.
# Usage: $0 -m <mode> -u <URL> -w <wordlist> [--ignore-cert] [-z <milliseconds>] [--no-check] [[--no-crt]] [[--no-slash]] [-f] [-v]
# Example: $0 -m sub -u https://example.com
#          $0 -m dir -u https://example.com/ -w directories.list
#          $0 -m file -u https://example.com/dir/ -w files.list
#          $0 -m wap -u https://example.com


# ---------------------------------------------------------------------------- #
# Functions
# ---------------------------------------------------------------------------- #
#=== Print help ===
usage() {
    echo "---+++===[ Web Buster ]===+++---"
    echo " A Web search tool for subdomains, directories, and files for a given URL."
    echo
    echo -e "    \033[1mUsage:\033[0m $0 -m <mode> -u <URL> -w <wordlist> [-i] [-z <milliseconds>] [-nc] [[-nC]] [[-ns]] [-f] [-v] [[-I]]"
    echo
    echo -e "\033[1mArguments:\033[0m"
    echo "  -h, --help                                  Print this help"
    echo "  -m, --mode <mode>                           Specify what to search for"
    echo "                                              The mode can be : sub (Subdomain discovery)"
    echo "                                                                dir (Directory discovery)"
    echo "                                                                file (File discovery)"
    echo "                                                                wap (Background information)"
    echo "  -u, --url <url>                             Specify a target"
    echo "  -w, --wordlist <wordlist>                   Specify a dictionary to use (Optional for Subdomain discovery) (Do not use with Background information)"
    echo
    echo -e "\033[1mOptional:\033[0m"
    echo "  -i, --ignore-cert                           Perform 'insecure' SSL connection"
    echo "  -z, --timer <milliseconds>                  Waiting between requests"
    echo "  -nc, --no-check                             Do not attempt to contact the site initially"
    echo "  -f, --follow                                Follow redirects"
    echo "  -p, --proxy <[protocol://]host[:port]>      Use this proxy"
    echo "  -A, --user-agent '<user-agent>'             Custom User Agent"
    echo "  -v, --verbose                               Verbose mode"
    echo "  -nC, --no-crt                               Do not check information from crt.sh|Certificate Search (Subdomain discovery only)"
    echo "  -ns, --no-slash                             Do not add a final '/' to the directory name (Directory discovery only)"
    echo "  -r, --recursive                             Recursive search (Subdomain and Directory discovery only)"
    echo "  -P, --max-parallel <max-parallel>           Multiprocessing (Do not use with Background information)"
    echo "  -I, --inhaler                               Additional search for links (Background information only)"
    echo
    echo
    echo -e "\033[1mExamples:\033[0m"
    echo "  $0 -m sub -u http://domain.com -w subdomains.list"
    echo "     * Subdomain discovery for 'http://domain.com' using the wordlist 'subdomains.list'."
    echo "  $0 --mode dir -u https://other.domain.com/somedire/ -w directories.list --ignore-cert"
    echo "     * Directory discovery for 'https://other.domain.com/somedire/' using the wordlist 'directories.list' and ignoring secutity certificates."
    echo "  $0 -m file -u https://www.another.com/files -w files.list --ignore-cert -z 200"
    echo "     * File discovery for 'https://www.another.com/files/' using the wordlist 'files.list' with a delay of 0.2s and ignoring secutity certificates."
    echo "  $0 -m dir -u https://againandagain.com/ -w directories.list --no-check --no-slash --verbose"
    echo "     * Directory discovery for 'https://againandagain.com/' using the wordlist 'directories.list'. Does not check if the target is up, does not add a final '/' to the directory name and display the currently tested directory."
    echo "  $0 --mode sub -u https://againagainagain.com"
    echo "     * Subdomain discovery for 'https://gainagainagain.com' using only Certificate Transparency logs."
    echo "  $0 --mode wap -u https://otherone.com -f"
    echo "     * Background information for 'https://otherone.com' following redirects"
    echo
}

#=== Certificate Transparency Logs [ crt.sh|Certificate Search ] ===
CTL() {
    echo " Requesting crt.sh..."
    # Curl request to retrieve the JSON list
    req=$(curl $CURLPROXY -s "https://crt.sh/?q=${domain}&output=json")

    if [ $? -ne 0 ] || [ -z "$req" ]; then
        echo -e "[!] Information from crt.sh|Certificate Search are not available.\n"
        return
    fi

    # Extract subdomains with jq
    mapfile -t subdomains < <(echo "$req" | jq -r '.[].name_value')

    # Sort and remove duplicates
    subdomains=($(printf "%s\n" "${subdomains[@]}" | sort -u))

    echo -e "[!] Information from crt.sh|Certificate Search\n"
    for subdomain in "${subdomains[@]}"; do
        echo "  $subdomain"
    done
    echo
    echo " Now checking which subdomains are up...."
    echo -e "[!] Requesting in progress...\n"

    # Checking which subdomains are up
    for subdomain in "${subdomains[@]}"; do
        TARGET="$protocol$subdomain"
        CONTROL_CODE="000"
        SUBDOMAIN="$subdomain"
        BUSTER
    done

    local discovered=$(cat "$DISCOVERED_TMP_FILE")
    # Nothing found
    if [[ $discovered == 0 ]]; then
        echo -e "[!] None of the subdomains seem to be up...\n"
    else
        # Clear the last line if the HTTP code is not good
        echo -e "\033[2K\r"
        echo -e "[+] End of Certificate Transparency Logs with $discovered item(s) found.\n"
    fi
    # Reset global counter
    echo 0 > "$DISCOVERED_TMP_FILE"
}

#=== Requester ===
BUSTER() {
    # Temp files for curl content
    local TMP_HTML=$(mktemp)
    local TMP_HEADERS=$(mktemp)
    echo "$TMP_HTML" >> "$TEMP_FILES"
    echo "$TMP_HEADERS" >> "$TEMP_FILES"

    local counter

    # Check if --ignore-cert is enabled to perform curl command
    if [[ $NOCERT ]]; then
        # Activate wap mode
        if [[ "$MODE" == "sub" ]]; then
            if [[ $FOLLOW == 1 ]]; then
                CODE_AND_LOCATION=$(curl $CURLPROXY -k -A "$USER_AGENT" -s -L -D "$TMP_HEADERS" -o "$TMP_HTML" -w "%{http_code} %{url_effective}" $TARGET)

                # Extract the HTTP code and the final location
                CODE=$(echo "$CODE_AND_LOCATION" | awk '{print $1}')
                FINAL_LOCATION=$(echo "$CODE_AND_LOCATION" | awk '{print $2}')
            else
                CODE=$(curl $CURLPROXY -k -A "$USER_AGENT" -s -D "$TMP_HEADERS" -o "$TMP_HTML" -w "%{http_code}" $TARGET)
            fi
        # No wap
        else
            if [[ $FOLLOW == 1 ]]; then
                CODE_AND_LOCATION=$(curl $CURLPROXY -k -A "$USER_AGENT" -s -L -o /dev/null -w "%{http_code} %{url_effective}" $TARGET)

                # Extract the HTTP code and the final location
                CODE=$(echo "$CODE_AND_LOCATION" | awk '{print $1}')
                FINAL_LOCATION=$(echo "$CODE_AND_LOCATION" | awk '{print $2}')
            else
                CODE=$(curl $CURLPROXY -k -A "$USER_AGENT" -s -o /dev/null -w "%{http_code}" $TARGET)
            fi
        fi
    # Take care to security certificates
    else
        # Activate wap mode
        if [[ "$MODE" == "sub" ]]; then
            if [[ $FOLLOW == 1 ]]; then
                CODE_AND_LOCATION=$(curl $CURLPROXY -A "$USER_AGENT" -s -L -D "$TMP_HEADERS" -o "$TMP_HTML" -w "%{http_code} %{url_effective}" $TARGET)

                # Extract the HTTP code and the final location
                CODE=$(echo "$CODE_AND_LOCATION" | awk '{print $1}')
                FINAL_LOCATION=$(echo "$CODE_AND_LOCATION" | awk '{print $2}')
            else
                CODE=$(curl $CURLPROXY -A "$USER_AGENT" -s -D "$TMP_HEADERS" -o "$TMP_HTML" -w "%{http_code}" $TARGET)
            fi
        # No wap
        else
            if [[ $FOLLOW == 1 ]]; then
                CODE_AND_LOCATION=$(curl $CURLPROXY -A "$USER_AGENT" -s -L -o /dev/null -w "%{http_code} %{url_effective}" $TARGET)

                # Extract the HTTP code and the final location
                CODE=$(echo "$CODE_AND_LOCATION" | awk '{print $1}')
                FINAL_LOCATION=$(echo "$CODE_AND_LOCATION" | awk '{print $2}')
            else
                CODE=$(curl $CURLPROXY -A "$USER_AGENT" -s -o /dev/null -w "%{http_code}" $TARGET)
            fi
        fi
    fi

    # Check the HTTP code and display discoveries
    if [[ "$CODE" != "$CONTROL_CODE" ]]; then
        IPADDR=""
        # DNS name resolution for subdomain enumeration
        if [[ "$MODE" == "sub" ]]; then
            #IPADDR="($(dig $SUBDOMAIN +short))"
            IPADDR=$(curl $CURLPROXY -s "https://cloudflare-dns.com/dns-query?name=example.com&type=A" -H "accept: application/dns-json" | jq -r '.Answer[0].data')
        fi
        # Show result
        echo "[+] $TARGET [$CODE] $IPADDR"

        if [[ -v FINAL_LOCATION ]]; then
            if [[ $TARGET != $FINAL_LOCATION ]]; then
                echo "[!] You have been redirected to: $FINAL_LOCATION"
            fi
        fi

        # If sub mode do WAP
        if [[ "$MODE" == "sub" ]]; then
            WAP
        fi

        # Add item to counter
        counter=$(cat "$DISCOVERED_TMP_FILE")
        ((counter++))
        echo "$counter" > "$DISCOVERED_TMP_FILE"

        # List new potential targets
        if [[ $RECURSIVE == 1 ]]; then
            if [[ $FOLLOW == 1 ]]; then
                if [[ $TARGET != $FINAL_LOCATION ]]; then
                    echo "$FINAL_LOCATION" >> "$EFFECTIVE_LOOT"
                else
                    echo "$TARGET" >> "$EFFECTIVE_LOOT"
                fi
            else
                echo "$TARGET" >> "$EFFECTIVE_LOOT"
            fi
        fi

    # Verbose
    elif [[ $VERBOSE == 1 ]]; then
        # Clear the last line if the HTTP code is not good
        echo -ne "\033[2K\r"
        echo -ne "Looking: $TARGET\r"
    fi

    # Sleep
    if [[ -v TIMER ]]; then
        sleep $(echo "$TIMER/1000" | bc -l)
    fi

    # Remove temp files
    rm -f "$TMP_HTML" "$TMP_HEADERS"
}

#=== WappalyzSofter ===
WAP() {
    echo "    |"
    # HTTP headers
    grep -iE 'Server:|X-Powered-By:|X-Generator|Set-Cookie:|CF-Ray:|X-Turbo-Charged-By:|Via:' "$TMP_HEADERS" | uniq | sed 's/^/    + /'

    #Cookies signatures
    #grep -i "Set-Cookie:" "$TMP_HEADERS" | grep -iE "wordpress|wp_|PHPSESSID|PrestaShop|shopify|laravel|symfony|mediawiki|phpbb" | sed 's/^/    + /'

    # CMS
    declare -A SIGNS

    SIGNS["WordPress"]="wp-content|wp-includes|WordPress|wp_|/xmlrpc.php"
    SIGNS["Drupal"]="Drupal|/sites/|/modules/|X-Generator: Drupal"
    SIGNS["Joomla"]="Joomla|/templates/|com_content|X-Content-Encoded-By"
    SIGNS["PrestaShop"]="PrestaShop|/js/jquery/plugins/blockcart|Set-Cookie: PrestaShop"
    SIGNS["Magento"]="Magento|/skin/frontend/|/static/frontend/"
    SIGNS["Shopify"]="cdn.shopify.com|Shopify.buy|shopify-assets"
    SIGNS["MediaWiki"]="MediaWiki|/load.php|id=\"mw-|class=\"mw-|X-Powered-By: PHP"
    SIGNS["phpBB"]="phpbb3_|phpbb_sid|phpbb"
    SIGNS["TYPO3"]="typo3|TSFE|typo3temp"
    SIGNS["Concrete5"]="concrete5|concrete5_cid"
    SIGNS["OpenCart"]="OpenCart|index.php?route=common/home|_oc_"
    SIGNS["Bitrix"]="Bitrix|BX_SESSION|bitrix_sessid"
    SIGNS["Squarespace"]="squarespace.com|squarespace-session"
    SIGNS["Ghost"]="ghost.js|ghost-content"
    SIGNS["ExpressionEngine"]="exp_sessionid|exp_tracker"
    SIGNS["MODX"]="modx_session|modxVisitorId"
    SIGNS["Umbraco"]="UmbracoPageId|umbSessionId"
    SIGNS["Craft CMS"]="craft\\_\\w+|craft\\_\\w+\\_"
    SIGNS["Pardot"]="pardot"
    SIGNS["VBulletin"]="vbforum|vBulletin|vbssl"
    SIGNS["Shopware"]="shopware"
    SIGNS["BigCommerce"]="bigcommerce"

    for TECH in "${!SIGNS[@]}"; do
      if grep -iqE "${SIGNS[$TECH]}" "$TMP_HTML" "$TMP_HEADERS"; then
        echo "    + CMS: $TECH"
      fi
    done

    # Search for versions in Meta generator
    grep -i '<meta name="generator"' "$TMP_HTML" | while read -r line; do
      content=$(echo "$line" | grep -Eo 'content="[^"]+"' | cut -d\" -f2)
      echo "    + CMS version: $content"
    done

    # Third-party platforms
    declare -A THIRD_SIGNS

    THIRD_SIGNS["Google Analytics"]="google-analytics|ga.js|gtag.js|analytics.js"
    THIRD_SIGNS["Google Tag Manager"]="googletagmanager"
    THIRD_SIGNS["Facebook Pixel"]="fbevents.js|facebook.com/tr"
    THIRD_SIGNS["Hotjar"]="hotjar"
    THIRD_SIGNS["New Relic"]="newrelic"
    THIRD_SIGNS["Vimeo"]="vimeo.com|player.vimeo.com"
    THIRD_SIGNS["YouTube"]="youtube.com|ytimg.com"
    THIRD_SIGNS["Wix"]="wix.com|static.parastorage.com|wixHTML"
    THIRD_SIGNS["Weebly"]="weebly.com|weebly"
    THIRD_SIGNS["Duda"]="duda.co"
    THIRD_SIGNS["Yampi"]="yampi.app"
    THIRD_SIGNS["Shopify"]="cdn.shopify.com|shopify-assets"
    THIRD_SIGNS["Stripe"]="stripe.com"
    THIRD_SIGNS["PayPal"]="paypal.com"
    THIRD_SIGNS["Mailchimp"]="mailchimp.com|chimpstatic.com"
    THIRD_SIGNS["SendGrid"]="sendgrid.net"
    THIRD_SIGNS["Intercom"]="intercom.io|widget.intercom.io"
    THIRD_SIGNS["FullStory"]="fullstory.com"
    THIRD_SIGNS["Optimizely"]="optimizely"
    THIRD_SIGNS["Segment"]="segment.com|cdn.segment.com"
    THIRD_SIGNS["HubSpot"]="hubspot"
    THIRD_SIGNS["Zendesk"]="zendesk.com|zdassets.com"
    THIRD_SIGNS["Matomo"]="matomo.js|piwik.js"

    for THIRD in "${!THIRD_SIGNS[@]}"; do
      if grep -iqE "${THIRD_SIGNS[$THIRD]}" "$TMP_HTML" "$TMP_HEADERS"; then
        echo "    + Third-party: $THIRD"
      fi
    done

    # JS Frameworks
    declare -A JS_SIGNS

    JS_SIGNS["Vue.js"]="vue.js|vue.runtime|data-v-"
    JS_SIGNS["React"]="react|react-dom|data-reactroot"
    JS_SIGNS["Angular"]="angular.min.js|ng-version|ng-app"
    JS_SIGNS["Ember.js"]="ember.min.js|id=\"ember"
    JS_SIGNS["Backbone.js"]="backbone.min.js"
    JS_SIGNS["Bootstrap"]="bootstrap.min.css|bootstrap.min.js"
    JS_SIGNS["jQuery"]="jquery.min.js|jquery.js|jquery"
    JS_SIGNS["Svelte"]="svelte\.js|svelte-hydration|svelte-routing"
    JS_SIGNS["Alpine.js"]="alpinejs|x-data=|x-bind:"
    JS_SIGNS["Mithril.js"]="mithril\.js|m\.mount"
    JS_SIGNS["Preact"]="preact|preact\.min\.js"
    JS_SIGNS["LitElement"]="lit-element|lit-html"
    JS_SIGNS["Next.js"]="__next|next\.js"
    JS_SIGNS["Nuxt.js"]="nuxt\.js"
    JS_SIGNS["RxJS"]="rxjs"
    JS_SIGNS["Tailwind CSS"]="tailwind"
    JS_SIGNS["Material UI"]="Mui|Material-UI"
    JS_SIGNS["Lodash"]="lodash|_\.js"
    JS_SIGNS["Moment.js"]="moment\.js"
    JS_SIGNS["Chart.js"]="Chart\.js|chartjs"
    JS_SIGNS["D3.js"]="d3\.js|d3-selection"

    for FRAMEW in "${!JS_SIGNS[@]}"; do
      if grep -iqE "${JS_SIGNS[$FRAMEW]}" "$TMP_HTML" "$TMP_HEADERS"; then
        echo "    + Framework: $FRAMEW"
      fi
    done

    # Search for versions
    grep -Eo '([a-z\-]+\.)?(react|angular|vue|jquery|bootstrap|moment|lodash)[\.-]([0-9]+\.[0-9]+(\.[0-9]+)?)' "$TMP_HTML" | sort -u | while read -r ver; do
      echo "    + Framework version: $ver"
    done

    # Servers and back-end
    declare -A SERVER_SIGNS
    SERVER_SIGNS["Apache"]="Server: Apache|Apache/|mod_rewrite"
    SERVER_SIGNS["Nginx"]="Server: nginx|nginx/"
    SERVER_SIGNS["LiteSpeed"]="Server: LiteSpeed|litespeed"
    SERVER_SIGNS["IIS"]="Server: Microsoft-IIS|ASP.NET"
    SERVER_SIGNS["Caddy"]="Server: Caddy|caddyserver"

    SERVER_SIGNS["Express.js"]="X-Powered-By: Express"
    SERVER_SIGNS["Flask"]="Server: Werkzeug|Python/|Flask"
    SERVER_SIGNS["Django"]="csrftoken|Set-Cookie: django|X-Frame-Options: DENY"
    SERVER_SIGNS["Ruby on Rails"]="Set-Cookie: _rails_|X-Runtime:|mod_rails"
    SERVER_SIGNS["Laravel"]="X-Powered-By: Laravel|Set-Cookie: laravel"
    SERVER_SIGNS["Symfony"]="Set-Cookie: symfony|X-Generator: Symfony|/bundles/framework"

    for BACK in "${!SERVER_SIGNS[@]}"; do
      if grep -iqE "${SERVER_SIGNS[$BACK]}" "$TMP_HTML" "$TMP_HEADERS"; then
        echo "    + Back: $BACK"
      fi
    done

    # Database engines
    declare -A DB_SIGNS

    DB_SIGNS["MySQL"]="MySQL server error|You have an error in your SQL syntax|mysqli_|SQLSTATE\[HY000\]"
    DB_SIGNS["PostgreSQL"]="PostgreSQL query failed|pg_connect\(|PostgreSQL.*ERROR"
    DB_SIGNS["SQLite"]="SQLite exception|SQLITE_ERROR|SQLite3::"
    DB_SIGNS["MongoDB"]="MongoError|MongoDB.Driver|mongodb://"
    DB_SIGNS["Redis"]="RedisException|Connection refused.*6379"
    DB_SIGNS["MariaDB"]="MariaDB server|MariaDB error"

    for DB in "${!DB_SIGNS[@]}"; do
      if grep -iqE "${DB_SIGNS[$DB]}" "$TMP_HTML"; then
        echo "    + DB: $DB"
      fi
    done

    # Cloud providers / services
    declare -A CLOUD_SIGNS

    CLOUD_SIGNS["Amazon AWS"]="amazonaws|aws.amazon|cloudfront|s3.amazonaws.com|x-amz-cf-"
    CLOUD_SIGNS["Microsoft Azure"]="azurewebsites.net|cloudapp.net|azure.microsoft.com|msedge.net|x-azure-ref|x-ms-edge-ref"
    CLOUD_SIGNS["Google Cloud Platform"]="googleapis.com|appspot.com|storage.googleapis.com|gcp|x-google-appengine"
    CLOUD_SIGNS["Cloudflare"]="cloudflare|cf-ray|cdn-cgi|cloudflare.com"
    CLOUD_SIGNS["Fastly"]="fastly.net|fastly"
    CLOUD_SIGNS["Akamai"]="akamai.net|akamaized.net|akamaitechnologies.com|akamai"
    CLOUD_SIGNS["DigitalOcean"]="digitaloceanspaces.com|digitalocean.com"
    CLOUD_SIGNS["Heroku"]="herokuapp.com"
    CLOUD_SIGNS["Oracle Cloud"]="oraclecloud.com|ocp.oraclecloud.com"
    CLOUD_SIGNS["IBM Cloud"]="bluemix.net|ibm.com"
    CLOUD_SIGNS["Alibaba Cloud"]="aliyuncs.com|alibaba-cloud.com"
    CLOUD_SIGNS["Vercel"]="vercel.app|now.sh"
    CLOUD_SIGNS["Netlify"]="netlify.app|netlify.com"
    CLOUD_SIGNS["StackPath"]="stackpathdns.com|stackpathcdn.com"
    CLOUD_SIGNS["Tencent Cloud"]="tencentcloudapi.com|tencentcloud.com"
    CLOUD_SIGNS["Squarespace CDN"]="squarespace.com|squarespace-session"
    CLOUD_SIGNS["Firebase"]="firebaseio.com|firebaseapp.com"
    CLOUD_SIGNS["Cloudinary"]="cloudinary.com"

    for CLOUD in "${!CLOUD_SIGNS[@]}"; do
      if grep -iqE "${CLOUD_SIGNS[$CLOUD]}" "$TMP_HTML" "$TMP_HEADERS"; then
        echo "    + Cloud: $CLOUD"
      fi
    done
    echo

    if [[ $INHALER == 1 ]]; then
        # <form action="">
        echo "    [FORM action]"
        grep -oP '(?i)<form\s+[^>]*action="\K[^"]+' "$TMP_HTML" | sort -u | while read -r action; do
            echo "        + $action"
        done
        # <script src="">
        echo "    [SCRIPT src]"
        grep -oP '(?i)<script\s+[^>]*src="\K[^"]+' "$TMP_HTML" | sort -u | while read -r src; do
            echo "        + $src"
        done
        # <iframe src="">
        echo "    [IFRAME src]"
        grep -oP '(?i)<iframe\s+[^>]*src="\K[^"]+' "$TMP_HTML" | sort -u | while read -r src; do
            echo "        + $src"
        done
        # <a href="">
        echo "    [A href]"
        grep -oP '(?i)<a\s+[^>]*href="\K[^"]+' "$TMP_HTML" | sort -u | while read -r href; do
            echo "        + $href"
        done
        # <link href="">
        echo "    [LINK href]"
        grep -oP '(?i)<link\s+[^>]*href="\K[^"]+' "$TMP_HTML" | sort -u | while read -r href; do
            echo "        + $href"
        done
    fi
    echo
}

#=== Recursive call ===
RECBUSTER() {
    # Add item to counter
    ((RECULEV++))

    # Return if no more items
    if [ ! -s "$OLD_LOOT" ]; then
        echo -e "\033[2K\r"
        echo -e " No items found."
        return
    else
        echo -e "\033[2K\r"
        echo " Recursion level: $RECULEV"
        echo -e "[!] Going deeper..."
    fi

    # Reinitialize new items list
    rm -f "$EFFECTIVE_LOOT"
    EFFECTIVE_LOOT=$(mktemp)
    echo "$EFFECTIVE_LOOT" >> "$TEMP_FILES"

    # Prepare new targets
    while IFS= read -r WHAT; do
        while IFS= read -r TARGET; do
            if [[ "$MODE" == "sub" ]]; then
                if [[ $TARGET =~ ^(https?://)([^/]+) ]]; then
                    protocol=${BASH_REMATCH[1]}
                    domain=${BASH_REMATCH[2]}
                    TARGET="$protocol$WHAT.$domain"
                fi
            else
                if [[ $NOSLASH == 1 ]]; then
                    TARGET="$TARGET$WHAT"
                else
                    TARGET="$TARGET$WHAT/"
                fi

            fi

            # Multiprocessing
            if [[ ! -z $MAXPARALLEL ]]; then
                BUSTER &

                pids+=($!)
                # Limit the number of concurrent jobs
                while (( ${#pids[@]} >= MAXPARALLEL )); do
                    for i in "${!pids[@]}"; do
                        if ! kill -0 "${pids[i]}" 2>/dev/null; then
                            unset 'pids[i]'
                        fi
                    done
                    # Reindex table
                    pids=("${pids[@]}")
                    sleep 0.1
                done
            # Non-parallel execution
            else
                BUSTER
            fi
        done < "$OLD_LOOT"
    done < "$WORDS"

    # Wait for the remaining jobs
    if [[ ! -z $MAXPARALLEL ]]; then
        wait
        pids=()
    fi

    # Check for new items
    mapfile -t old < "$OLD_LOOT"
    mapfile -t effective < "$EFFECTIVE_LOOT"
    old_sorted=($(printf "%s\n" "${old[@]}" | sort -u))
    effective_sorted=($(printf "%s\n" "${effective[@]}" | sort -u))

    # If new items make a loop
    if [[ "${old_sorted[*]}" != "${effective_sorted[*]}" ]]; then
        cp "$EFFECTIVE_LOOT" "$OLD_LOOT"
        RECBUSTER
    fi
}

#=== SIGINT ===
on_sigint() {
    # Wait for the remaining jobs (if any)
    wait
    # Clean files
    echo " Clean up..."
    clean
    echo "The program terminated prematurely."
    exit 1
}
# Catch SIGINT
trap on_sigint SIGINT

#=== Clean temp files ===
clean() {
    while read temp_file; do
        if [[ -f "$temp_file" ]]; then
            rm -f "$temp_file"
        fi
    done < "$TEMP_FILES"
    rm -f "$TEMP_FILES"
}


# ---------------------------------------------------------------------------- #
# Argument management
# ---------------------------------------------------------------------------- #
#=== No argument, print Usage and exit ===
if [[ $# -eq 0 ]]; then
    echo -e "---+++===[ Web Buster ]===+++---\n A Web search tool for subdomains, directories, and files.\n"
    echo -e "\033[1mUsage:\033[0m $0 -m <mode> -u <URL> -w <wordlist> [--ignore-cert] [-z <milliseconds>] [--no-check] [[--no-crt]] [[--no-slash]] [-f] [-v]\n"
    echo -e "Type '$0 --help' for more information."
    exit 1
fi

#=== Index ===
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage; exit 0 ;;
        -m|--mode) MODE=$2; shift ;;
        -u|--url) URL="$2"; shift ;;
        -w|--wordlist) WORDS="$2"; shift ;;
        -i|--ignore-cert) NOCERT=1 ;;
        -z|--timer) TIMER=$2; shift ;;
        -nc|--no-check) NOCHECK=1 ;;
        -p|--proxy) PROXY="$2"; shift ;;
        -A|--user-agent) UA="$2"; shift ;;
        -v|--verbose) VERBOSE=1 ;;
        -nC|--no-crt) NOCRT=1 ;;
        -ns|--no-slash) NOSLASH=1 ;;
        -r|--recursive) RECURSIVE=1 ;;
        -f|--follow) FOLLOW=1 ;;
        -P|--max-parallel) MAXPARALLEL=$2; shift ;;
        -I|--inhaler) INHALER=1 ;;
        *) echo -e "\nError : Bad argument $1.\n"; exit 1 ;;
    esac
    shift
done

#=== Title ===
echo -e "---+++===[ Web Buster ]===+++---\n A Web search tool for subdomains, directories, and files.\n"

#=== Required arguments ===
if [[ -z "$MODE" ]]; then
    echo -e "Error : --mode is required.\n"
    exit 1
elif [[ -z "$URL" ]]; then
    echo -e "Error : --url is required.\n"
    exit 1
elif [[ -z "$WORDS" ]]; then
    if [[ "$MODE" != "sub" && "$MODE" != "wap" ]]; then
        echo -e "Error : --wordlist is required.\n"
        exit 1
    elif [[ "$MODE" == "sub" ]]; then
        # crt-only
        CRTO=1
    fi
fi

#=== Bad CRTO ===
if [[ -v WORDS && -v CRTO ]]; then
    echo -e "Error : Bad argument : Cannot use wordlist with crt-only.\n"
    exit 1
fi
if [[ -v NOCRT && -v CRTO ]]; then
    echo -e "Error : Bad argument : Cannot use no-crt without wordlist.\n"
    exit 1
fi

#=== Bad arguments and modes ===
if [[ "$MODE" == "sub" ]]; then
    if [[ $NOSLASH == 1 ]]; then
        echo -e "Error : Bad argument : Cannot use no-slash with subdomain discovery mode.\n"
        exit 1
    fi
elif [[ "$MODE" == "file" ]]; then
    if [[ $NOSLASH == 1 ]]; then
        echo -e "Error : Bad argument : Cannot use no-slash with file discovery mode.\n"
        exit 1
    fi
    if [[ $NOCRT == 1 ]]; then
        echo -e "Error : Bad argument : Cannot use no-crt with file discovery mode.\n"
        exit 1
    fi
#=== Bad modes ===
elif [[ "$MODE" != "dir" && "$MODE" != "wap" ]]; then
    echo -e "Error : Bad mode : $MODE.\n"
    exit 1
else
    if [[ $NOCRT == 1 ]]; then
        echo -e "Error : Bad argument : Cannot use no-crt with dir discovery mode.\n"
        exit 1
    fi
fi

#=== Wap mode ===
if [[ "$MODE" == "wap" ]]; then
    if [[ -v WORDS ]]; then
        echo -e "Error : Bad argument : Cannot use wordlist with background information mode.\n"
        exit 1
    elif [[ -v TIMER ]]; then
        echo -e "Error : Bad argument : Cannot use timer with background information mode.\n"
        exit 1
    elif [[ $NOCHECK == 1 ]]; then
        echo -e "Error : Bad argument : Cannot use no-check with background information mode.\n"
        exit 1
    elif [[ $VERBOSE == 1 ]]; then
    echo -e "Error : Bad argument : Cannot use verbose with background information mode.\n"
        exit 1
    elif [[ $NOCRT == 1 ]]; then
        echo -e "Error : Bad argument : Cannot use no-crt with background information mode.\n"
        exit 1
    elif [[ $NOSLASH == 1 ]]; then
        echo -e "Error : Bad argument : Cannot use no-slash with background information mode.\n"
        exit 1
    fi
fi

#=== Inhaler ===
if [[ "$MODE" != "wap" && $INHALER == 1 ]]; then
    echo -e "Error : Bad argument : Cannot use inhaler without background information mode.\n"
    exit 1
fi

#=== Recursive option ===
if [[ "$MODE" != "sub" && "$MODE" != "dir" && $RECURSIVE == 1 ]]; then
    echo -e "Error : Bad argument : Cannot use recursive without subdomain discovery or directory discovery mode.\n"
    exit 1
fi

#=== Multiprocessing ===
if [[ "$MODE" == "wap" && -v MAXPARALLEL ]]; then
    echo -e "Error : Cannot use multiprocessing in this mode.\n"
    exit 1
elif [[ -v MAXPARALLEL && ! "$MAXPARALLEL" =~ ^[0-9]+$ ]]; then
    echo -e "Error : Multiprocessing must be expressed an integer.\n"
    exit 1
else
    # Useful for multiprocess management
    pids=()
fi

#=== Check whether the URL begins with HTTP or HTTPS ===
if [[ $URL =~ ^(https?://)([^/]+) ]]; then
    protocol=${BASH_REMATCH[1]}  # "https://"
    domain=${BASH_REMATCH[2]}    # "domain.com"

    if [[ "$MODE" == "sub" ]]; then
        echo "[+] MODE : Subdomain Buster"
    else
        # The string does not end with a slash
        if [[ ! "$URL" =~ /$ ]]; then
            URL="$URL/"
        fi
        if [[ "$MODE" == "file" ]]; then
            echo "[+] MODE : File Buster"
        elif [[ "$MODE" == "dir" ]]; then
            echo "[+] MODE : Directory Buster"
        elif [[ "$MODE" == "wap" ]]; then
            echo "[+] MODE : Background Buster"
        fi
    fi
    echo -e "[+] TARGET : $URL\n"
else
    echo -e "Error : Bad URL format.\n"
    exit 1
fi

#=== If a timer is defined, it must be an integer ===
if [[ -v TIMER ]]; then
    if [[ ! "$TIMER" =~ ^[0-9]+$ ]]; then
        echo -e "Error : Time must be expressed in milliseconds.\n"
        exit 1
    fi
fi

#=== Warns the user that the connection should be considered insecure ===
if [[ $NOCERT == 1 ]]; then
    echo -e "\033[1m--ignore-cert is enabled :\033[0m Treat all connections as 'insecure'."
fi

#=== Basic curl setup ===
# User agent
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
if [[ -v UA ]]; then
    USER_AGENT="$UA"
fi
# Proxy
if [[ -v PROXY ]]; then
    proxy_regex='^((http|socks4|socks5)://)?[^:/ ]+(:[0-9]+)?$'
    # Check that the proxy is correct
    if [[ "$PROXY" =~ $proxy_regex ]]; then
        CURLPROXY="--proxy $PROXY"
        echo "[!] Proxy in use : $PROXY"
    else
        echo "Error : Invalid proxy format: $PROXY"
        exit 1
    fi
else
    # If not set keep empty
    CURLPROXY=""
fi

#=== Temporary file indexing temporary files ===
TEMP_FILES=$(mktemp)

#=== If recursive, prepare storage for new targets ===
if [[ $RECURSIVE == 1 ]]; then
    OLD_LOOT=$(mktemp);
    EFFECTIVE_LOOT=$(mktemp);
    echo "$OLD_LOOT" >> "$TEMP_FILES";
    echo "$EFFECTIVE_LOOT" >> "$TEMP_FILES";
    # Recursion level
    RECULEV=0
fi


# ---------------------------------------------------------------------------- #
# MAIN
# ---------------------------------------------------------------------------- #
#=== Check that the target is reachable ===
if [[ $NOCHECK != 1 ]]; then
    # Create temporary files to store the HTTP response and index them
    TMP_HTML=$(mktemp)
    TMP_HEADERS=$(mktemp)
    echo "$TMP_HTML" >> "$TEMP_FILES"
    echo "$TMP_HEADERS" >> "$TEMP_FILES"

    echo " Checking that the target is reachable..."
    # Curl
    if [[ $NOCERT == 1 ]]; then
        if [[ $FOLLOW == 1 ]]; then
            CODE_AND_LOCATION=$(curl $CURLPROXY -k -A "$USER_AGENT" -s -L -D "$TMP_HEADERS" -o "$TMP_HTML" -w "%{http_code} %{url_effective}" --max-time 10 $URL)

            # Extract the HTTP code and the final location
            CHECK_CODE=$(echo "$CODE_AND_LOCATION" | awk '{print $1}')
            FINAL_LOCATION=$(echo "$CODE_AND_LOCATION" | awk '{print $2}')
        else
            CHECK_CODE=$(curl $CURLPROXY -k -A "$USER_AGENT" -s -D "$TMP_HEADERS" -o "$TMP_HTML" -w "%{http_code}" --max-time 10 $URL)
        fi
    else
        if [[ $FOLLOW == 1 ]]; then
            CODE_AND_LOCATION=$(curl $CURLPROXY -A "$USER_AGENT" -s -L -D "$TMP_HEADERS" -o "$TMP_HTML" -w "%{http_code} %{url_effective}" --max-time 10 $URL)

            # Extract the HTTP code and the final location
            CHECK_CODE=$(echo "$CODE_AND_LOCATION" | awk '{print $1}')
            FINAL_LOCATION=$(echo "$CODE_AND_LOCATION" | awk '{print $2}')
        else
            CHECK_CODE=$(curl $CURLPROXY -A "$USER_AGENT" -s -D "$TMP_HEADERS" -o "$TMP_HTML" -w "%{http_code}" --max-time 10 $URL)
        fi
    fi
    # Target is down
    if [[ "$CHECK_CODE" == "000" ]]; then
        echo -e "\nError : The provided URL seems to be down. Try ‘--ignore-cert’ option\n"
        clean
        exit 1
    fi

    # Target is up, resolve DNS name
    #IPADDR=$(dig $domain +short)
    IPADDR=$(curl $CURLPROXY -s "https://cloudflare-dns.com/dns-query?name=example.com&type=A" -H "accept: application/dns-json" | jq -r '.Answer[0].data')
    echo "[+] $URL is up [$CHECK_CODE] ($IPADDR)"

    # If redirects know where
    if [[ -v FINAL_LOCATION ]]; then
        if [[ $URL != $FINAL_LOCATION ]]; then
            echo "[!] You have been redirected to: $FINAL_LOCATION"
        fi
    fi

    # Background information on the target
    WAP

    # If in wap mode then close the program
    if [[ "$MODE" == "wap" ]]; then
        echo -e "The program terminated successfully."
        clean
        exit 0
    fi

    # Remove temp HTTP response
    rm -f "$TMP_HTML" "$TMP_HEADERS"
fi

#=== Temporary counter file for parallelism ===
DISCOVERED_TMP_FILE=$(mktemp)
echo 0 > "$DISCOVERED_TMP_FILE"
echo "$DISCOVERED_TMP_FILE" >> "$TEMP_FILES"

#=== Call CTL to request crt.sh|Certificate Search ===
if [[ "$MODE" == "sub" ]]; then
    if [[ $NOCRT != 1 ]]; then
        CTL
    fi
fi

#=== Close the program if crt-only is set to 1 ===
if [[ $CRTO == 1 ]]; then
    echo -e "The program terminated successfully."
    clean
    exit 0
fi

#=== Dictionary path ===
echo " Enumerate..."
echo -e "[!] Browsing dictionary in progress...\n"

#=== Loop on the dictionary ===
while IFS= read -r WHAT; do
    # Prepare the target URL
    if [[ "$MODE" == "sub" ]]; then
        TARGET="$protocol$WHAT.$domain"
        CONTROL_CODE="000"
        SUBDOMAIN="$WHAT.$domain"
        LOOT="subdomains"
    elif [[ "$MODE" == "file" ]]; then
        TARGET="$URL$WHAT"
        CONTROL_CODE="404"
        LOOT="files"
    elif [[ "$MODE" == "dir" ]]; then
        if [[ $NOSLASH == 1 ]]; then
            TARGET="$URL$WHAT"
        else
            TARGET="$URL$WHAT/"
        fi
        CONTROL_CODE="404"
        LOOT="directories"
    fi

    # Multiprocessing
    if [[ ! -z $MAXPARALLEL ]]; then
        BUSTER &

        pids+=($!)
        # Limit the number of concurrent jobs
        while (( ${#pids[@]} >= MAXPARALLEL )); do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[i]}" 2>/dev/null; then
                    unset 'pids[i]'
                fi
            done
            # Reindex table
            pids=("${pids[@]}")
            sleep 0.1
        done
    # Non-parallel execution
    else
        BUSTER
    fi
# Use wordlist as input
done < "$WORDS"

#=== Wait for the remaining jobs ===
if [[ ! -z $MAXPARALLEL ]]; then
    wait
    pids=()
fi

#=== Recursive mode ===
if [[ $RECURSIVE == 1 ]]; then
    # Check for new items
    mapfile -t old < "$OLD_LOOT"
    mapfile -t effective < "$EFFECTIVE_LOOT"
    old_sorted=($(printf "%s\n" "${old[@]}" | sort -u))
    effective_sorted=($(printf "%s\n" "${effective[@]}" | sort -u))

    # If new items send to RECBUSTER
    if [[ "${old_sorted[*]}" != "${effective_sorted[*]}" ]]; then
        cp "$EFFECTIVE_LOOT" "$OLD_LOOT"
        RECBUSTER
    fi
fi

#=== Retrieve the number of items ===
DISCOVERED=$(cat "$DISCOVERED_TMP_FILE")

#=== Clean ===
clean

#=== Nothing found ===
if [[ $DISCOVERED == 0 ]]; then
    if [[ NOCERT != 1 ]]; then
        echo -e "[!] No $LOOT were found. Try ‘--ignore-cert’ option.\n"
    else
        echo -e "[!] No $LOOT were found.\n"
    fi
#=== Success ===
else
    # Clear the last line if the HTTP code is not good
    echo -e "\033[2K\r"
    echo -e "[+] End of dictionary enumeration with $DISCOVERED item(s) found.\n"
    echo -e "The program terminated successfully."
fi
