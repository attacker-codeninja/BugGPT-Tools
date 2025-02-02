#!/usr/bin/bash

#A bit of Styling
RED='\033[31m'
GREEN='\033[32m'
DGREEN='\033[38;5;28m'
GREY='\033[37m'
BLUE='\033[34m'
YELLOW='\033[33m'
PURPLE='\033[35m'
PINK='\033[38;5;206m'
RESET='\033[0m'
NC='\033[0m'

#Banner
echo -e "${PURPLE}"
cat << "EOF"
        ╭┳╮
╭┳┳┳━┳┳┳╯┣╋┳┳━━╮
┃W┃O┃R╭┫D┃I┃U┃M┃
╰━━┻━┻╯╰━┻┻━┻┻┻╯
EOF
echo -e "${NC}"
##Currently Tracking Wordlists:
# ~ >  70K --> https://github.com/reewardius/bbFuzzing.txt
# ~ >   5K --> https://github.com/Bo0oM/fuzz.txt
# ~ > 180K --> https://github.com/thehlopster/hfuzz
# ~ > 1.8K --> https://github.com/ayoubfathi/leaky-paths
# ~ > 760K --> https://github.com/six2dez/OneListForAll
# ~ > 1.1M --> https://github.com/rix4uni/WordList
##Optimal Goal
# x-mini.txt      --> ~ <  15K 
# x-lhf-mini.txt  --> ~ <  50K
# x-lhf-mid.txt   --> ~ < 100K
# x-lhf-large.txt --> ~ < 500K
# x-massive.txt   --> ~ <   1M

#Help / Usage
if [[ "$*" == *"-h"* ]] || [[ "$*" == *"--help"* ]] || [[ "$*" == *"help"* ]] ; then
  echo -e "${YELLOW}➼ Usage${NC}: ${PURPLE}wordium${NC} ${BLUE}-w${NC} ${GREEN}</path/to/your/wordlist/directory> ${NC}"
       if [ -z "$WORDLIST" ]; then
         echo -e "${BLUE}Current Default${NC}: ${GREEN}$(echo $HOME/.wordlist)${NC}\n"  
       else
         echo -e "${BLUE}Current Default${NC}: ${GREEN}$(echo $WORDLIST)${NC}\n"
       fi
  echo -e "${YELLOW}Extended Help${NC}"
  echo -e "${BLUE}-w${NC},  ${BLUE}--wordlist-dir${NC}     Specify where to create your wordlists (${YELLOW}Required${NC}, else specify as ${GREEN}\$WORDLIST${NC} in ${RED}\$ENV:VAR)${NC}\n"
  echo -e "${BLUE}-q${NC},  ${BLUE}--quick${NC}            ${GREEN}Quick Mode${NC} [${YELLOW}Only Use if ${RED}not first time${NC}]"
  echo -e "${BLUE}-up${NC}, ${BLUE}--update${NC}           ${GREEN}Update ${PURPLE}wordium${NC}\n"
  echo -e "${YELLOW}Example Usage${NC}: "
  echo -e "${PURPLE}wordium${NC} -w ${BLUE}/tmp/wordlists${NC}\n"  
  echo -e "➼ ${YELLOW}Don't Worry${NC} if your ${RED}Terminal Hangs${NC} for a bit.. It's a feature not a bug"
  exit 0
fi

# Update. Github caches take several minutes to reflect globally  
if [[ $# -gt 0 && ( "$*" == *"up"* || "$*" == *"-up"* || "$*" == *"update"* || "$*" == *"--update"* ) ]]; then
  echo -e "➼ ${YELLOW}Checking For ${BLUE}Updates${NC}"
      if ping -c 2 github.com > /dev/null; then
      REMOTE_FILE=$(mktemp)
      curl -s -H "Cache-Control: no-cache" https://raw.githubusercontent.com/Azathothas/BugGPT-Tools/main/wordium/wordium.sh -o "$REMOTE_FILE"
         if ! diff --brief /usr/local/bin/wordium "$REMOTE_FILE" >/dev/null 2>&1; then
             echo -e "➼ ${YELLOW}NEW!! Update Found! ${BLUE}Updating ..${NC}" 
             dos2unix $REMOTE_FILE > /dev/null 2>&1 
             sudo mv "$REMOTE_FILE" /usr/local/bin/wordium && echo -e "➼ ${GREEN}Updated${NC} to ${BLUE}@latest${NC}\n" 
             echo -e "➼ ${YELLOW}ChangeLog:${NC} ${DGREEN}$(curl -s https://api.github.com/repos/Azathothas/BugGPT-Tools/commits?path=wordium/wordium.sh | jq -r '.[0].commit.message')${NC}"
             echo -e "➼ ${YELLOW}Pushed at${NC}: ${DGREEN}$(curl -s https://api.github.com/repos/Azathothas/BugGPT-Tools/commits?path=wordium/wordium.sh | jq -r '.[0].commit.author.date')${NC}\n"
             sudo chmod +xwr /usr/local/bin/wordium
             rm -f "$REMOTE_FILE" 2>/dev/null
             else
             echo -e "➼ ${YELLOW}Already ${BLUE}UptoDate${NC}"
             echo -e "➼ Most ${YELLOW}recent change${NC} was on: ${DGREEN}$(curl -s https://api.github.com/repos/Azathothas/BugGPT-Tools/commits?path=wordium/wordium.sh | jq -r '.[0].commit.author.date')${NC} [${DGREEN}$(curl -s https://api.github.com/repos/Azathothas/BugGPT-Tools/commits?path=wordium/wordium.sh | jq -r '.[0].commit.message')${NC}]\n"             
             rm -f "$REMOTE_FILE" 2>/dev/null
             exit 0
             fi
     else
         echo -e "➼ ${YELLOW}Github.com${NC} is ${RED}unreachable${NC}"
         echo -e "➼ ${YELLOW}Try again later!${NC} "
         exit 1
     fi
  exit 0
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -w|--wordlist-dir)
         if [ -z "$2" ]; then
             echo -e "${RED}Error: ${YELLOW}Wordlist Directory${NC} is missing for option ${BLUE}'-w | --wordlist-dir'${NC}"
             exit 1
         fi        
        WORDLIST="$(realpath "$2")"
        shift 
        shift 
        ;;                                                        
        *)    
        echo -e "${RED}Error: Invalid option ${YELLOW}'$key'${NC} , see ${BLUE}--help${NC} for Usage"
        exit 1
        ;;
    esac
done
#Check Net
if ! ping -c 5 github.com > /dev/null; then
   echo -e "${RED}\u2717 Fatal${NC}: ${YELLOW}No Internet${NC}\n"
 exit 1
fi

# Check if WORDLIST is already set in the environment
if [ -z "$WORDLIST" ]; then
  echo -e "Path for ${BLUE}WORDLIST${NC} is ${RED}not set in the environment or specified as an option.${NC}" >&2
  echo -e "➼ Will choose ${BLUE}$HOME/Wordlist${NC} as default directory"
  echo -e "➼ ${YELLOW}If You don't want that, hit ${RED}ctrl + c${NC} now!"
  echo -e "➼ ${YELLOW}Waiting 10 Seconds${NC} ${GREEN}before continuing${NC} in ${BLUE}$HOME/Wordlist${NC}" && sleep 15s
  mkdir -p $HOME/Wordlist
  export WORDLIST="$HOME/Wordlist" 
  cd "$WORDLIST"
else
  echo -e "➼ ${YELLOW}Specified Wordlist Directory${NC}: ${BLUE}$(echo $WORDLIST)${NC}\n" && sleep 5s
  mkdir -p "$WORDLIST" && cd "$WORDLIST"
fi

#Dependency Checks
#Golang
if ! command -v go &> /dev/null 2>&1; then
    echo "➼ golang is not installed. Installing..."
    cd $update_golang && git clone https://github.com/udhos/update-golang  && cd $update_golang/update-golang && sudo ./update-golang.sh
    source /etc/profile.d/golang_path.sh
else
    GO_VERSION=$(go version | awk '{print $3}')
if [[ "$(printf '%s\n' "1.20.0" "$(echo "$GO_VERSION" | sed 's/go//')" | sort -V | head -n1)" != "1.20.0" ]]; then
        echo "➼ golang version 1.20.0 or greater is not installed. Installing..."
        update_golang=$(mktemp)
        cd $update_golang && git clone https://github.com/udhos/update-golang  && cd $update_golang/update-golang && sudo ./update-golang.sh
        source /etc/profile.d/golang_path.sh
    else
        echo ""
    fi
fi
#anew
if ! command -v anew &> /dev/null; then
   echo "➼ anew is not installed. Installing..." 
   go install -v github.com/tomnomnom/anew@latest
fi
#dos2unix, for updates
if ! command -v dos2unix >/dev/null 2>&1; then
    echo "➼ dos2unix is not installed. Installing..."
    sudo apt-get update && sudo apt-get install dos2unix -y
fi

#Dirs
dirs=("$WORDLIST/bbFuzzing.txt" "$WORDLIST/fuzz.txt" "$WORDLIST/hfuzz" "$WORDLIST/leaky-paths" "$WORDLIST/OneListForAll" "$WORDLIST/WordList")
#paths for redundancy 
paths=("$WORDLIST/bbFuzzing.txt/bbFuzzing.txt" "$WORDLIST/fuzz.txt/fuzz.txt" "$WORDLIST/hfuzz/hfuzz.txt" "$WORDLIST/leaky-paths/leaky-paths.txt" "$WORDLIST/OneListForAll/onelistforallmicro.txt" "$WORDLIST/WordList/onelistforall.txt")   
#funcs
setup_dirs_base(){
    echo -e "${YELLOW}This will take quite some time${NC} (If first run)" 
    echo -e "Depending on your ${YELLOW}internet${NC}, it ${RED}may take upto 1 hr${NC}" 
    echo -e "${BLUE}Just let your terminal be!${NC}"  
    git config --global --add safe.directory $(pwd)
    #Rood's base for lhf wordlists
    wordium_rood_lhf=$(mktemp)
    wget --quiet https://raw.githubusercontent.com/Azathothas/BugGPT-Tools/main/misc/wordlists/rood-lhf.txt -O $wordium_rood_lhf
    cat "$wordium_rood_lhf" | anew -q "$WORDLIST/x-lhf-mini.txt"
}
setup_dirs_submodules(){
    echo -e "ⓘ  ${BLUE}Proceeding${NC} with ${PINK}Submodules${NC}"
    #Submodules
    git submodule add https://github.com/reewardius/bbFuzzing.txt 2>/dev/null
    git submodule add https://github.com/Bo0oM/fuzz.txt 2>/dev/null
    git submodule add https://github.com/thehlopster/hfuzz 2>/dev/null
    git submodule add https://github.com/ayoubfathi/leaky-paths 2>/dev/null
    git submodule add https://github.com/six2dez/OneListForAll 2>/dev/null
    git submodule add https://github.com/rix4uni/WordList 2>/dev/null
}   
setup_dirs_clones(){
   echo -e "No Git ${YELLOW}(.git)${NC} folder found in "$WORDLIST" or its parent directories!"
   echo -e "Proceeding with ${BLUE}git clone${NC}\n"
    #Clones
    cd "$WORDLIST"
    git clone https://github.com/reewardius/bbFuzzing.txt 2>/dev/null
    git clone https://github.com/Bo0oM/fuzz.txt 2>/dev/null
    git clone https://github.com/thehlopster/hfuzz 2>/dev/null
    git clone https://github.com/ayoubfathi/leaky-paths 2>/dev/null
    git clone https://github.com/six2dez/OneListForAll 2>/dev/null
    git clone https://github.com/rix4uni/WordList 2>/dev/null
}
#main check
setup_wordlist(){
   for dir in "${dirs[@]}"; do
      if [ ! -d "$dir" ]; then 
       echo -e "${RED}\u2717 Error${NC}: ${BLUE}"$dir"${RED} not found${NC}"   
        if [ -d "../$dir/.git" ]; then
           echo -e "ⓘ  ${PINK}Git ${YELLOW}(.git)${NC} detected in ${YELLOW}"../$dir/.git"${NC}"
           setup_dirs_base && setup_dirs_submodules
        elif [ -d "../../$dir/.git" ]; then
           echo -e "ⓘ  ${PINK}Git ${YELLOW}(.git)${NC} detected in ${YELLOW}"../../$dir/.git"${NC}"
           setup_dirs_base && setup_dirs_submodules  
        elif [ -d "../../../$dir/.git" ]; then
           echo -e "ⓘ  ${PINK}Git ${YELLOW}(.git)${NC} detected in ${YELLOW}"../../../$dir/.git"${NC}"
           setup_dirs_base && setup_dirs_submodules
        else
           setup_dirs_base && setup_dirs_clones
        fi
        #Mark Safe
        find "$WORDLIST" -type d -exec sh -c 'cd "$0" && git config --global --add safe.directory "$(pwd)"' {} \; 2>/dev/null
      fi      
   done
}

#Git Pull
for path in "${paths[@]}"; do
  if [ ! -f "$path" ]; then
      echo -e "${RED}\u2717 Error${NC}: ${BLUE}$path${RED} not found${NC}"
      echo -e "${PURPLE}Reinstalling....${NC}\n"
      setup_wordlist
  else #update git deps
  updates_made=false
    for dir in "${dirs[@]}"; do  
       if [ -d "$dir" ]; then 
          echo -e "${BLUE}Updating ${PURPLE}"$dir" ${YELLOW}to ${DGREEN}@latest${NC}"
          if cd "$dir" && git config --global --add safe.directory "$(pwd)" 2>/dev/null; then
             if [[ $(git pull) == *"Already up to date."* ]]; then
               echo -e "${YELLOW}ⓘ Already ${DGREEN}@latest${NC}" 
             else
               echo -e "${GREEN}\u2713 Fetched${DGREEN} <----> ${PURPLE}Synced ${NC}"
               updates_made=true
             fi  
          else #reset & resolve conflict
             cd "$dir" && git config --global --add safe.directory "$(pwd)" 2>/dev/null && git fetch --all 2>/dev/null && git reset --hard origin/main 2>/dev/null && git clean -fd 2>/dev/null  
             if [[ $(git pull) == *"Already up to date."* ]]; then
               echo -e "${YELLOW}ⓘ Already ${DGREEN}@latest${NC}" 
               updates_made=true
             else
               echo -e "${GREEN}\u2713 Fetched${DGREEN} <----> ${PURPLE}Synced ${NC}"
               updates_made=true
             fi 
          fi          
       fi
    done  
    if ! "$updates_made"; then
      break  # Exit the loop if no updates were made
    fi    
  fi  
done


# #Sync Repos to @latest
# find "$WORDLIST" -type d -exec sh -c 'cd "$0" && git config --global --add safe.directory "$(pwd)"' {} \; 2>/dev/null
# echo -e "\n"
# find "$WORDLIST" -maxdepth 1 -type d -exec sh -c '(cd {} && echo "Updating {} to @latest" && git pull 2>/dev/null )' \;
# echo -e "\n"

#Begins
#echo -e "➼${YELLOW}Fetching & Updating${NC} from ${BLUE}WORDLIST/WORDLIST${NC} \n" 
#echo -e "➼ ${BLUE}x-lhf-mini.txt${NC}  : $()${NC}" 
##Prints anything with . (dot)
#grep -E '^\.' file.txt
## Removes lines with digits, and removes slashes from beginning of each line 
#sed '/[0-9]/d' file.txt | sed '/^[[:space:]]*$/d' | sed 's#^/##'
#Init
echo "test" | anew -q $WORDLIST/x-lhf-mini.txt
lhf_mini_lines=$(wc -l < $WORDLIST/x-lhf-mini.txt)
## --> Bo0oM/fuzz.txt
echo ""
echo -e "➼ ${YELLOW}Fetching & Updating${NC} ${DGREEN}<-- ${BLUE}Bo0oM/fuzz.txt${NC}" 
echo -e "➼ ${BLUE}x-lhf-mini.txt${NC}  : ${GREEN}$(grep -E '^\.' $WORDLIST/fuzz.txt/fuzz.txt | anew $WORDLIST/x-lhf-mini.txt | wc -l)${NC}" 
echo -e "➼ ${BLUE}x-lhf-mid.txt${NC}  : ${GREEN}$(cat $WORDLIST/fuzz.txt/fuzz.txt | anew $WORDLIST/x-lhf-mid.txt | wc -l)${NC}\n" 

## --> reewardius/bbFuzzing.txt
echo -e "➼ ${YELLOW}Fetching & Updating${NC} ${DGREEN}<-- ${BLUE}reewardius/bbFuzzing.txt${NC}"
echo -e "➼ ${BLUE}x-lhf-mini.txt${NC}  : ${GREEN}$(grep -E '^\.' $WORDLIST/bbFuzzing.txt/bbFuzzing.txt | anew $WORDLIST/x-lhf-mini.txt | wc -l)${NC}" 
echo -e "➼ ${BLUE}x-lhf-mid.txt ${NC}  : ${GREEN}$(cat $WORDLIST/bbFuzzing.txt/bbFuzzing.txt | grep -Ei 'api|build|conf|dev|env|git|graph|helm|json|kube|k8|sql|swagger|xml|yaml|yml|wadl|wsdl' | anew $WORDLIST/x-lhf-mid.txt | wc -l)${NC}" 
echo -e "➼ ${BLUE}x-lhf-large.txt${NC}  : ${GREEN}$(cat $WORDLIST/bbFuzzing.txt/bbFuzzing.txt | anew $WORDLIST/x-lhf-large.txt | wc -l)${NC}\n" 

## --> thehlopster/hfuzz
echo -e "➼ ${YELLOW}Fetching & Updating${NC} ${DGREEN}<-- ${BLUE}thehlopster/hfuzz${NC}" 
echo -e "➼ ${BLUE}x-lhf-mini.txt${NC}  : ${GREEN}$(grep -E '^\.' $WORDLIST/hfuzz/hfuzz.txt | anew $WORDLIST/x-lhf-mini.txt | wc -l)${NC}" 
echo -e "➼ ${BLUE}x-lhf-large.tx${NC}  : ${GREEN}$(sed '/[0-9]/d' $WORDLIST/hfuzz/hfuzz.txt | sed '/^[[:space:]]*$/d' | sed 's#^/##' |  grep -Ei 'api|build|conf|dev|env|git|graph|helm|json|kube|k8|sql|swagger|xml|yaml|yml|wadl|wsdl' | anew $WORDLIST/x-lhf-large.txt | wc -l)${NC}\n" 

## --> ayoubfathi/leaky-paths
echo -e "➼ ${YELLOW}Fetching & Updating${NC} ${DGREEN}<-- ${BLUE}ayoubfathi/leaky-paths${NC}" 
echo -e "➼ ${BLUE}x-lhf-mini.txt${NC}  : ${GREEN}$(sed '/[0-9]/d' $WORDLIST/leaky-paths/leaky-paths.txt | sed '/^[[:space:]]*$/d' | anew $WORDLIST/x-lhf-mini.txt | wc -l)${NC}\n" 

## --> Six2dez/OneListForAll
echo -e "➼ ${YELLOW}Fetching & Updating${NC} ${DGREEN}<-- ${BLUE}Six2dez/OneListForAll${NC}" 
echo -e "➼ ${BLUE}x-lhf-mini.txt${NC}  : ${GREEN}$(grep -E '^\.' $WORDLIST/OneListForAll/onelistforallmicro.txt | anew $WORDLIST/x-lhf-mini.txt | wc -l)${NC}" 
echo -e "➼ ${BLUE}x-lhf-large.txt${NC}  : ${GREEN}$(cat $WORDLIST/OneListForAll/onelistforallshort.txt | grep -Ei 'api|build|conf|dev|env|git|graph|helm|json|kube|k8|sql|swagger|xml|yaml|yml|wadl|wsdl' | anew $WORDLIST/x-lhf-large.txt | wc -l)${NC}" 
echo -e "➼ ${BLUE}x-massive.txt${NC}  : ${GREEN}$(cat $WORDLIST/OneListForAll/onelistforallshort.txt | anew $WORDLIST/x-massive.txt | wc -l)${NC}\n" 

## --> rix4uni/WordList
echo -e "➼ ${YELLOW}Fetching & Updating${NC} ${DGREEN}<-- ${BLUE}rix4uni/WordList${NC}" 
echo -e "➼ ${BLUE}x-lhf-mini.txt${NC}  : ${GREEN}$(grep -E '^\.' $WORDLIST/WordList/onelistforall.txt | anew $WORDLIST/x-lhf-mini.txt | wc -l) , $(grep -E '^\.' $WORDLIST/WordList/onelistforshort.txt | anew $WORDLIST/x-lhf-mini.txt | wc -l)${NC}" 
echo -e "➼ ${BLUE}x-lhf-mid.txt${NC}  : ${GREEN}$(cat $WORDLIST/WordList/admin-panel-paths.txt | anew $WORDLIST/x-lhf-mid.txt | wc -l)${NC}" 
echo -e "➼ ${BLUE}x-lhf-large.txt${NC}  : ${GREEN}$(cat $WORDLIST/WordList/onelistforshort.txt | sed 's#^/##' | anew $WORDLIST/x-lhf-large.txt | wc -l)${NC}" 
echo -e "➼ ${BLUE}x-massive.txt${NC}  : ${GREEN}$(sed '/[0-9]/d' $WORDLIST/WordList/onelistforall.txt | sed '/^[[:space:]]*$/d' | sed 's#^/##' |  grep -Ei 'api|build|conf|dev|env|git|graph|helm|json|kube|k8|sql|swagger|xml|yaml|yml|wadl|wsdl' | anew $WORDLIST/x-massive.txt | wc -l)${NC}\n" 

#Anew & CleanUP
echo -e "➼ ${YELLOW}New Additions${NC} "
x_lhf_mini_lines=$(wc -l < "$WORDLIST/x-lhf-mini.txt")
echo -e "➼ ${BLUE}x-lhf-mini.txt${NC}  : ${GREEN}$(( $x_lhf_mini_lines - $lhf_mini_lines ))${NC}" 
echo -e "➼ ${BLUE}x-lhf-mid.txt${NC}   : ${GREEN}$(cat $WORDLIST/x-lhf-mini.txt | anew $WORDLIST/x-lhf-mid.txt | wc -l)${NC}" 
echo -e "➼ ${BLUE}x-lhf-large.txt${NC} : ${GREEN}$(cat $WORDLIST/x-lhf-mid.txt | anew $WORDLIST/x-lhf-large.txt | wc -l)${NC}" 
echo -e "➼ ${BLUE}x-massive.txt${NC}   : ${GREEN}$(cat $WORDLIST/x-lhf-large.txt | anew $WORDLIST/x-massive.txt | wc -l)${NC}\n" 
#Sort -u -o everything 
find $WORDLIST -maxdepth 1 -type f -name "*.txt" -not -name ".*" -exec sort -u {} -o {} \;  

#x-api.txt
echo -e "➼ ${YELLOW}Generating ${BLUE}x-api.txt${NC} " 
#Prefetch base for x-mini.txt
tmp_wordium_api=$(mktemp)
#Base
wget --quiet "https://raw.githubusercontent.com/Azathothas/BugGPT-Tools/main/misc/wordlists/g-api.txt" -O $tmp_wordium_api
cat $tmp_wordium_api | anew -q $WORDLIST/x-api-tiny.txt
#Trim space, remove /
cat $WORDLIST/x-massive.txt | sed '/^[[:space:]]*$/d' | sed 's#^/##' |  grep -Ei 'api|api2|api3|graph|json|rest|soap|swagger|v1|v2|v3|v4|xml|wadl|wsdl' | anew -q $tmp_wordium_api
sort -u $tmp_wordium_api -o $tmp_wordium_api
echo -e "➼ ${YELLOW}Newly added${NC}: ${GREEN}$(cat $tmp_wordium_api | anew $WORDLIST/x-api.txt | wc -l)${NC}\n"

#x-dns.txt
echo -e "➼ ${YELLOW}Generating ${BLUE}x-dns.txt${NC} " 
tmp_wordium_dns=$(mktemp)
tmp_wordium_nokovo=$(mktemp)
#Base
wget --quiet "https://raw.githubusercontent.com/Azathothas/BugGPT-Tools/main/misc/wordlists/dns-sub-permutate.txt" -O $tmp_wordium_dns
cat $tmp_wordium_dns | anew -q $WORDLIST/x-dns-tiny.txt
#n0kovo_subdomains tiny
wget --quiet "https://raw.githubusercontent.com/n0kovo/n0kovo_subdomains/main/n0kovo_subdomains_small.txt" -O $tmp_wordium_nokovo
#Separate by dots & dashes
cat $tmp_wordium_nokovo | tr -s '\n' | grep '^[[:alpha:]]\+$' | sort -u | anew -q $tmp_wordium_dns
sort -u $tmp_wordium_dns -o $tmp_wordium_dns
echo -e "➼ ${YELLOW}Newly added${NC}: ${GREEN}$(cat $tmp_wordium_dns | anew $WORDLIST/x-dns.txt | wc -l)${NC}\n"

#x-mini.txt
echo -e "➼ ${YELLOW}Generating ${BLUE}x-mini.txt${NC} " 
#Prefetch base for x-mini.txt
tmp_wordium_mini=$(mktemp)
wget --quiet "https://raw.githubusercontent.com/Azathothas/BugGPT-Tools/main/misc/wordlists/fuzz-mini.txt" -O $tmp_wordium_mini
cat $WORDLIST/fuzz.txt/fuzz.txt $WORDLIST/leaky-paths/leaky-paths.txt | sed 's#^/##' | anew -q $tmp_wordium_mini
grep -E '^\.' $WORDLIST/x-lhf-large.txt | anew -q $tmp_wordium_mini
sort -u $tmp_wordium_mini -o $tmp_wordium_mini
echo -e "➼ ${YELLOW}Newly added${NC}: ${GREEN}$(cat $tmp_wordium_mini | anew $WORDLIST/x-mini.txt | wc -l)${NC}\n"

#WordCount After each run:
echo -e "➼${YELLOW}Updated Wordlists${NC}:" 
echo -e "➼ ${BLUE}x-api.txt${NC}       : ${GREEN}$(wc -l $WORDLIST/x-api.txt)${NC}" 
echo -e "➼ ${BLUE}x-api-tiny.txt${NC}  : ${GREEN}$(wc -l $WORDLIST/x-api-tiny.txt)${NC}"
echo -e "➼ ${BLUE}x-dns.txt${NC}       : ${GREEN}$(wc -l $WORDLIST/x-dns.txt)${NC}"
echo -e "➼ ${BLUE}x-dns-tiny.txt${NC}  : ${GREEN}$(wc -l $WORDLIST/x-dns-tiny.txt)${NC}"
echo -e "➼ ${BLUE}x-mini.txt${NC}      : ${GREEN}$(wc -l $WORDLIST/x-mini.txt)${NC}" 
echo -e "➼ ${BLUE}x-lhf-mini.txt${NC}  : ${GREEN}$(wc -l $WORDLIST/x-lhf-mini.txt)${NC}" 
echo -e "➼ ${BLUE}x-lhf-mid.txt${NC}   : ${GREEN}$(wc -l $WORDLIST/x-lhf-mid.txt)${NC}" 
echo -e "➼ ${BLUE}x-lhf-large.txt${NC} : ${GREEN}$(wc -l $WORDLIST/x-lhf-large.txt)${NC}"
echo -e "➼ ${BLUE}x-massive.txt${NC}   : ${GREEN}$(wc -l $WORDLIST/x-massive.txt)${NC}\n" 

#Sort -u -o everything , again
find $WORDLIST -maxdepth 1 -type f -name "*.txt" -not -name ".*" -exec sort -u {} -o {} \;  

#Check For Update on Script end
#Update. Github caches take several minutes to reflect globally  
   if ping -c 2 github.com > /dev/null; then
      REMOTE_FILE=$(mktemp)
      curl -qfksSL "https://raw.githubusercontent.com/Azathothas/BugGPT-Tools/main/wordium/wordium.sh" -H "Cache-Control: no-cache" -o "$REMOTE_FILE"
         if ! diff --brief /usr/local/bin/wordium "$REMOTE_FILE" >/dev/null 2>&1; then
              echo ""
              echo -e "➼ ${YELLOW}Update Found!${NC} ${BLUE}updating ..${NC} $(wordium -up)" 
         else
            rm -f "$REMOTE_FILE" 2>/dev/null
              exit 0
         fi
   fi
#EOF
