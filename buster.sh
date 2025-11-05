#!/bin/bash

# Search for subdomains, directories, and files for a given URL.
# Usage: $0 -m <mode> -u <URL> -w <wordlist> [--ignore-cert] [-z <milliseconds>] [--no-check] [[--no-crt]] [[--crt-only]] [[--no-slash]] [-v]
# Example: $0 -m sub -u https://example.com -w subdomains.list

# Print help
usage() {
    echo "---+++===[ Web Buster ]===+++---"
    echo " A Web search tool for subdomains, directories, and files for a given URL."
    echo
    echo -e "    \033[1mUsage:\033[0m $0 -m <mode> -u <URL> -w <wordlist> [--ignore-cert] [-z <milliseconds>] [--no-check] [[--no-crt]] [[--crt-only]] [[--no-slash]] [-v]"
    echo
    echo -e "\033[1mArguments:\033[0m"
    echo "  -h, --help                                  Print this help"
    echo "  -m <mode>, --mode <mode>                    Specify what to search for"
    echo "                                              The mode can be : sub (subdomain discovery)"
    echo "                                                                dir (directory discovery)"
    echo "                                                                file (file discovery)"
    echo "  -u <url>, --url <url>                       Specify a target"
    echo "  -w <wordlist>, --wordlist <wordlist>        Specify a dictionary to use"
    echo
    echo -e "\033[1mOptional:\033[0m"
    echo "  -i, --ignore-cert                           Perform 'insecure' SSL connection"
    echo "  -z <milliseconds>, --timer <milliseconds>   Waiting between requests"
    echo "  -nc, --no-check                             Do not attempt to contact the site initially"
    echo "  -v, --verbose                               Verbose mode"
    echo
    echo -e "\033[1mMode sub only:\033[0m"
    echo "  -nC, --no-crt                               Do not check information from crt.sh|Certificate Search"
    echo "  -c, --crt-only                              Do not perform a dictionary attack. Cannot be used with -w|--wordlist"
    echo
    echo -e "\033[1mMode dir only:\033[0m"
    echo "  -ns, --no-slash                             Do not add a final '/' to the directory name"
    echo
    echo -e "\033[1mExamples:\033[0m"
    echo "  $0 -m sub -u http://domain.com -w subdomains.list"
    echo "  $0 --mode dir -u https://other.domain.com/somedire/ -w directories.list --ignore-cert"
    echo "  $0 -m file -u https://www.another.com/files -w files.list --ignore-cert -z 200"
    echo "  $0 -m dir -u https://againandagain.com/ -w directories.list --no-check --no-slash --verbose"
    echo "  $0 --mode sub -u https://againagainagain.com -c"
    echo
}

# crt.sh|Certificate Search check | Certificate Transparency Logs
crt() {
    echo " Requesting crt.sh..."
    # Curl request to retrieve the JSON list
    req=$(curl -s "https://crt.sh/?q=${domain}&output=json")

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
    echo -e "[!] Now checking which subdomains are up....\n"

    # Checking which subdomains are up
    discovered=0
    for subdomain in "${subdomains[@]}"; do
        target="$protocol$subdomain"
        # Check if --ignore-cert is enabled to perform a curl command
        if [[ $NOCERT ]]; then
            code=$(curl -k -s -o /dev/null -w "%{http_code}" $target)
        else
            code=$(curl -s -o /dev/null -w "%{http_code}" $target)
        fi

        # Displays discoveries
        if [[ "$code" != "000" ]]; then
            # DNS name resolution
            ipaddr=$(dig $subdomain +short)
            # Show result
            echo "  $target [$code] $ipaddr"
            ((discovered++))
        elif [[ $VERBOSE == 1 ]]; then
            # Clear the last line if the HTTP code is not good
            echo -ne "\033[2K\r"
            echo -ne "$target\r"
        fi

        # Sleep
        if [[ -v TIMER ]]; then
            sleep $(echo "$TIMER/1000" | bc -l)
        fi
    done

    # Nothing found
    if [[ $discovered == 0 ]]; then
        echo -e "[!] None of the subdomains seem to be up...\n"
    else
        # Clear the last line if the HTTP code is not good
        echo -e "\033[2K\r"
        echo -e "[!] End of Certificate Transparency Logs results.\n"
    fi
}

# No argument, print Usage and exit
if [[ $# -eq 0 ]]; then
    echo -e "---+++===[ Web Buster ]===+++---\n A Web search tool for subdomains, directories, and files.\n"
    echo -e "\033[1mUsage:\033[0m $0 -m <mode> -u <URL> -w <wordlist> [--ignore-cert] [-z <milliseconds>] [--no-check] [[--no-crt]] [[--crt-only]] [[--no-slash]] [-v]\n"
    echo -e "Type '$0 --help' for more information."
    exit 1
fi

# Argument management
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage; exit 0 ;;
        -m|--mode) MODE=$2; shift ;;
        -u|--url) URL="$2"; shift ;;
        -w|--wordlist) WORDS="$2"; shift ;;
        -i|--ignore-cert) NOCERT=1 ;;
        -z|--timer) TIMER=$2; shift ;;
        -nc|--no-check) NOCHECK=1 ;;
        -v|--verbose) VERBOSE=1 ;;
        -nC|--no-crt) NOCRT=1 ;;
        -c|--crt-only) CRTO=1 ;;
        -ns|--no-slash) NOSLASH=1 ;;
        *) echo -e "\nError : Bad argument $1.\n"; exit 1 ;;
    esac
    shift
done

# Title
echo -e "---+++===[ Web Buster ]===+++---\n A Web search tool for subdomains, directories, and files.\n"

# Required arguments
if [[ -z "$MODE" ]]; then
    echo -e "Error : --mode is required.\n"
    exit 1
elif [[ -z "$URL" ]]; then
    echo -e "Error : --url is required.\n"
    exit 1
elif [[ -z "$WORDS" ]]; then
    if [[ "$MODE" != "sub" ]]; then
        echo -e "Error : --wordlist is required.\n"
        exit 1
    elif [[ $CRTO != 1 ]]; then
        echo -e "Error : --wordlist is required.\n"
        exit 1
    fi
fi

# Bad argument
if [[ -v WORDS && -v CRTO ]]; then
    echo -e "Error : Bad argument : Cannot use wordlist with crt-only.\n"
    exit 1
fi
if [[ -v NOCRT && -v CRTO ]]; then
    echo -e "Error : Bad argument : Cannot use no-crt with crt-only.\n"
    exit 1
fi

# Bad argument
if [[ "$MODE" == "sub" ]]; then
    if [[ $NOSLASH == 1 ]]; then
        echo -e "Error : Bad argument : Cannot use no-slash with subdomain discovery.\n"
        exit 1
    fi
elif [[ "$MODE" == "file" ]]; then
    if [[ $NOSLASH == 1 ]]; then
        echo -e "Error : Bad argument : Cannot use no-slash with file discovery.\n"
        exit 1
    fi
    if [[ $NOCRT == 1 ]]; then
        echo -e "Error : Bad argument : Cannot use no-crt with file discovery.\n"
        exit 1
    fi
# Bad mode
elif [[ "$MODE" != "dir" ]]; then
    echo -e "Error : Bad mode : $MODE.\n"
    exit 1
else
    if [[ $NOCRT == 1 ]]; then
        echo -e "Error : Bad argument : Cannot use no-crt with dir discovery.\n"
        exit 1
    fi
fi

# Check whether the URL begins with HTTP or HTTPS
if [[ $URL =~ ^(https?://)([^/]+) ]]; then

    if [[ "$MODE" == "sub" ]]; then
        protocol=${BASH_REMATCH[1]}  # "https://"
        domain=${BASH_REMATCH[2]}    # "domain.com"
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
        fi
    fi
    echo -e "[+] TARGET : $URL\n"
else
    echo -e "Error : Bad URL format.\n"
    exit 1
fi

# If a timer is defined, it must be an integer
if [[ -v TIMER ]]; then
    if [[ ! "$TIMER" =~ ^[0-9]+$ ]]; then
        echo -e "Error : Time must be expressed in milliseconds.\n"
        exit 1
    fi
fi

# Warns the user that the connection should be considered insecure
if [[ $NOCERT == 1 ]]; then
    echo -e "\033[1m--ignore-cert is enabled :\033[0m Treat all connections as 'insecure'."
fi

# Check that the target is reachable
if [[ $NOCHECK != 1 ]]; then
    if [[ $NOCERT == 1 ]]; then
        CHECK_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" $URL)
    else
        CHECK_CODE=$(curl -s -o /dev/null -w "%{http_code}" $URL)
    fi
    if [[ "$CHECK_CODE" == "000" ]]; then
        echo -e "Error : The provided URL seems to be down.\n"
        exit 1
    fi
fi

# Call crt to request crt.sh|Certificate Search
if [[ "$MODE" == "sub" ]]; then
    if [[ $NOCRT != 1 ]]; then
        crt
    fi
fi

# Close the program if crt-only is set to 1
if [[ $CRTO == 1 ]]; then
    echo -e "\nThe program terminated successfully."
    exit 0
fi

# Dictionary path
echo " Enumerate..."
echo -e "[!] Browsing dictionary in progress...\n"

# Number of loot items
DISCOVERED=0
# Check the HTTP code and display discoveries
while read WHAT; do
    # Prepare the target URL
    if [[ "$MODE" == "sub" ]]; then
        TARGET="$protocol$WHAT.$domain"
        CONTROL_CODE="000"
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

    # Check if --ignore-cert is enabled to perform a curl command
    if [[ $NOCERT ]]; then
        CODE=$(curl -k -s -o /dev/null -w "%{http_code}" $TARGET)
    else
        CODE=$(curl -s -o /dev/null -w "%{http_code}" $TARGET)
    fi

    # Displays discoveries
    if [[ "$CODE" != "$CONTROL_CODE" ]]; then
        # If subdomain mode DNS name resolution
        IPADDR=""
        if [[ "$MODE" == "sub" ]]; then
            IPADDR=$(dig $WHAT.$domain +short)
        fi
        # Show result
        echo "  $TARGET [$CODE] $IPADDR"
        ((DISCOVERED++))
    elif [[ $VERBOSE == 1 ]]; then
        # Clear the last line if the HTTP code is not good
        echo -ne "\033[2K\r"
        echo -ne "$TARGET\r"
    fi

    # Sleep
    if [[ -v TIMER ]]; then
        sleep $(echo "$TIMER/1000" | bc -l)
    fi
# Use wordlist as input
done < "$WORDS"

# Nothing found
if [[ $DISCOVERED == 0 ]]; then
    echo -e "[!] No $LOOT were found. Try the ‘--ignore-cert’ option.\n"
else
    # Clear the last line if the HTTP code is not good
    echo -e "\033[2K\r"
    echo -e "[!] End of dictionary enumeration.\n"
    echo -e "\nThe program terminated successfully."
fi
