#!/bin/bash

# Search for subdomains, directories, and files for a given URL.
# Usage: $0 -m <mode> -u <URL> -w <wordlist> [--ignore-cert] [-z <milliseconds>] [--no-check] [[--no-slash]]
# Example: $0 -m sub -u https://example.com -w subdomains.list

# Print help
usage() {
    echo "---+++===[ Web Buster ]===+++---"
    echo " A Web search tool for subdomains, directories, and files."
    echo
    echo -e "    \033[1mUsage:\033[0m $0 -m <mode> -u <URL> -w <wordlist> [--ignore-cert] [-z <milliseconds>] [--no-check] [[--no-slash]]"
    echo
    echo -e "\033[1mArguments:\033[0m"
    echo "  -h, --help                                  Print this help."
    echo "  -m <mode>, --mode <mode>                    Specify what to search for."
    echo "                                              The mode can be : sub (subdomain discovery),"
    echo "                                                                dir (directory discovery),"
    echo "                                                                file (file discovery)."
    echo "  -u <url>, --url <url>                       Specify a target."
    echo "  -w <wordlist>, --wordlist <wordlist>        Specify a dictionnary to use."
    echo
    echo -e "\033[1mOptional:\033[0m"
    echo "  --ignore-cert                               Perform 'insecure' SSL connection."
    echo "  -z <milliseconds>, --timer <milliseconds>   Waiting between requests."
    echo "  --no-check                                  Do not attempt to contact the site initially."
    echo "  -v, --verbose                               Verbose mode."
    echo
    echo -e "\033[1mMode dir only:\033[0m"
    echo "  --no-slash                                  Do not add a final '/' to the directory name."
    echo
    echo -e "\033[1mExamples:\033[0m"
    echo "  $0 -m sub -u http://domain.com -w subdomains.list"
    echo "  $0 --mode dir -u https://other.domain.com/somedire/ -w directories.list --ignore-cert"
    echo "  $0 -m file -u https://www.another.com/files -w files.list --ignore-cert -z 200"
    echo "  $0 -m dir -u https://againandagain.com/ -w directories.list --no-check --no-slash"
    echo
}

# No argument, print Usage and exit
if [[ $# -eq 0 ]]; then
    echo -e "---+++===[ Web Buster ]===+++---\n A Web search tool for subdomains, directories, and files.\n"
    echo -e "\033[1mUsage:\033[0m $0 -m <mode> -u <URL> -w <wordlist> [--ignore-cert] [-z <milliseconds>] [[--no-slash]]\n"
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
        --ignore-cert) NOCERT=1 ;;
        -z|--timer) TIMER=$2; shift ;;
        --no-check) NOCHECK=1 ;;
        -v|--verbose) VERBOSE=1 ;;
        --no-slash) NOSLASH=1 ;;
        *) echo -e "\nError : Bad argument $1.\n"; exit 1 ;;
    esac
    shift
done

# Title
echo -e "---+++===[ Web Buster ]===+++---\n A Web search tool for subdomains, directories, and files.\n"

# Required arguments
if [[ -z "$MODE" ]]; then
    echo -e "\nError : --mode is required.\n"
    exit 1
elif [[ -z "$URL" ]]; then
    echo -e "\nError : --url is required.\n"
    exit 1
elif [[ -z "$WORDS" ]]; then
    echo -e "\nError : --wordlist is required.\n"
    exit 1
fi

# Bad argument
if [[ "$MODE" == "sub" ]]; then
    if [[ $NOSLASH == 1 ]]; then
        echo -e "\nError : Bad argument --no-slash.\n"
        exit 1
    fi
elif [[ "$MODE" == "file" ]]; then
    if [[ $NOSLASH == 1 ]]; then
        echo -e "\nError : Bad argument --no-slash.\n"
        exit 1
    fi
# Bad mode
elif [[ "$MODE" != "dir" ]]; then
    echo -e "\nError : Bad mode : $MODE.\n"
    exit 1
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
    echo "[+] TARGET : $URL"
else
    echo -e "Error : Bad URL format.\n"
    exit 1
fi

# If a timer is defined, it must be an integer
if [[ -v TIMER ]]; then
    if [[ ! "$TIMER" =~ ^[0-9]+$ ]]; then
        echo -e "\nError : Time must be expressed in milliseconds.\n"
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
        echo -e "\nError : The provided URL seems to be down.\n"
        exit 1
    fi
fi

# Add a blank line for clarity
echo -e " Searching...\n"
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
        echo "  $TARGET [$CODE]"
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
fi
