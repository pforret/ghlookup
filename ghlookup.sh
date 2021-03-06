#!/usr/bin/env bash
### Created by Peter Forret ( pforret ) on 2020-10-04
script_version="0.0.0"  # if there is a VERSION.md in this script's folder, it will take priority for version number
readonly script_author="peter@forret.com"
#readonly script_creation="2020-10-04"
readonly run_as_root=-1 # run_as_root: 0 = don't check anything / 1 = script MUST run as root / -1 = script MAY NOT run as root

list_options() {
echo -n "
flag|h|help|show usage
flag|q|quiet|no output
flag|v|verbose|output more
flag|f|force|do not ask for confirmation (always yes)
option|l|log_dir|folder for debug files |$HOME/log/ghlookup
option|t|tmp_dir|folder for temp files|$HOME/.tmp
option|a|accept|accept header (e.g. application/vnd.github.mercy-preview+json)|
param|1|action|user/repo/repos/tags/langs/topics
param|1|ident|<user> or <user/repo>
param|1|field|field to retrieve: field to retrieve: . / .field / .[].name / @
" | grep -v '^#'
}

#####################################################################
## Put your main script here
#####################################################################

main() {
    debug "Program: $script_basename $script_version"
    debug "Updated: $prog_modified"
    debug "Run as : $USER@$HOSTNAME"
    # add programs you need in your script here, like tar, wget, ffmpeg, rsync ...
    verify_programs awk basename cut date dirname find grep head mkdir sed stat tput uname wc jq
    prep_log_and_temp_dir

    # shellcheck disable=SC2154
    case $action in
    user )
      [[ "$field" == "@" ]] && field=".name"
      gh_api "/users/$ident"            "$field"
     ;;

    repo )
      [[ "$field" == "@" ]] && field=".description"
      gh_api "/repos/$ident"            "$field"
      ;;

    repos )
      [[ "$field" == "@" ]] && field=".[].full_name"
      gh_api "/users/$ident/repos"      "$field"
      ;;

    tags )
      [[ "$field" == "@" ]] && field=".[].name"
      gh_api "/repos/$ident/tags"       "$field"
      ;;

    langs )
      [[ "$field" == "@" ]] && field="keys[]"
      gh_api "/repos/$ident/languages" "$field"
      ;;

    topics )
	# cf https://docs.github.com/en/rest/reference/repos#get-all-repository-topics
      [[ "$field" == "@" ]] && field=".names[]"
      debug "field=/$field/"
      accept="application/vnd.github.mercy-preview+json"
      gh_api "/repos/$ident/topics"    "$field"
      ;;

    files )
      [[ "$field" == "@" ]] && field=".[].name"
      debug "field=/$field/"
      gh_api  "/repos/$ident/contents" "$field"
      ;;

    *)      die "action [$action] not recognized"
    esac
}

#####################################################################
## Put your helper scripts here
#####################################################################

gh_api() {
  # $1 = relative API URL
  # $2 = jq query path
  local relative="$1"
  local api_endpoint="https://api.github.com"
  local field="${2:-.}"

  if [[ -n "${GH_PERSONAL_TOKEN:-}" ]] ; then
    debug "Using authentication [$GH_PERSONAL_ID]" 
    local authentication="-u $GH_PERSONAL_ID:$GH_PERSONAL_TOKEN"
  else
    local authentication=""
  fi

  local full_url="$api_endpoint$relative"
  debug "API URL: $full_url"
  local uniq
  uniq=$(echo "$full_url" | hash 10)
  # shellcheck disable=SC2154
  local cached="$tmp_dir/github.$uniq.json"
  use_cache=1
  [[  ! -f "$cached" ]] && use_cache=0
  [[  -f "$cached" ]] && grep -q '{' "$cached" || use_cache=0
  if [[ $use_cache -eq 0 ]] ; then
    if [[ -n "$accept" ]] ; then
      debug "Accept: $accept"
      curl_accept="-H 'Accept: $accept'"
    else
      curl_accept=""
    fi
    debug "Save to: $cached"
    # shellcheck disable=SC2086
    curl -s "$authentication" "$curl_accept" "$full_url" > "$cached"
    if [[ $(< "$cached" wc -c) -lt 10 ]] ; then
      rm "$cached"
      die "API call to [$full_url] came back with empty response"
    fi
  else
      debug "Cached : $cached"
  fi
  if [[ "$field" ==  "." ]] ; then
    < "$cached" jq "$field"
  else
    debug "JSON jq: $field"
    < "$cached" jq "$field" | sed 's/"//g' | sed 's/,$//' | tee "$tmp_dir/query.$uniq$2.txt"
  fi
}

#####################################################################
################### DO NOT MODIFY BELOW THIS LINE ###################

# set strict mode -  via http://redsymbol.net/articles/unofficial-bash-strict-mode/
# removed -e because it made basic [[ testing ]] difficult
set -uo pipefail
IFS=$'\n\t'
# shellcheck disable=SC2120
hash(){
  length=${1:-6}
  # shellcheck disable=SC2230
  if [[ -n $(which md5sum) ]] ; then
    # regular linux
    md5sum | cut -c1-"$length"
  else
    # macos
    md5 | cut -c1-"$length"
  fi 
}


prog_modified="??"
os_name=$(uname -s)
[[ "$os_name" = "Linux" ]]  && prog_modified=$(stat -c %y    "${BASH_SOURCE[0]}" 2>/dev/null | cut -c1-16) # generic linux
[[ "$os_name" = "Darwin" ]] && prog_modified=$(stat -f "%Sm" "${BASH_SOURCE[0]}" 2>/dev/null) # for MacOS

force=0
help=0

## ----------- TERMINAL OUTPUT STUFF

[[ -t 1 ]] && piped=0 || piped=1        # detect if out put is piped
verbose=0
#to enable verbose even before option parsing
[[ $# -gt 0 ]] && [[ $1 == "-v" ]] && verbose=1
quiet=0
#to enable quiet even before option parsing
[[ $# -gt 0 ]] && [[ $1 == "-q" ]] && quiet=1

[[ $(echo -e '\xe2\x82\xac') == '€' ]] && unicode=1 || unicode=0 # detect if unicode is supported


if [[ $piped -eq 0 ]] ; then
  col_reset="\033[0m" ; col_red="\033[1;31m" ; col_grn="\033[1;32m" ; col_ylw="\033[1;33m"
else
  col_reset="" ; col_red="" ; col_grn="" ; col_ylw=""
fi

if [[ $unicode -gt 0 ]] ; then
  char_succ="✔" ; char_fail="✖" ; char_alrt="➨" ; char_wait="…"
else
  char_succ="OK " ; char_fail="!! " ; char_alrt="?? " ; char_wait="..."
fi

readonly nbcols=$(tput cols || echo 80)
readonly wprogress=$((nbcols - 5))

out() { ((quiet)) || printf '%b\n' "$*";  }
progress() {
  ((quiet)) || (
    ((piped)) && out "$*" || printf "... %-${wprogress}b\r" "$*                                             ";
  )
}
die()     { tput bel; out "${col_red}${char_fail} $script_basename${col_reset}: $*" >&2; safe_exit; }
alert()   { out "${col_red}${char_alrt}${col_reset}: $*" >&2 ; }                       # print error and continue
success() { out "${col_grn}${char_succ}${col_reset}  $*" ; }
announce(){ out "${col_grn}${char_wait}${col_reset}  $*"; sleep 1 ; }
debug()   { ((verbose)) && out "${col_ylw}# $* ${col_reset}" >&2 ; }

lower_case()   { echo "$*" | awk '{print tolower($0)}' ; }
upper_case()   { echo "$*" | awk '{print toupper($0)}' ; }
confirm() { is_set $force && return 0; read -r -p "$1 [y/N] " -n 1; echo " "; [[ $REPLY =~ ^[Yy]$ ]];}

ask() {
  # $1 = variable name
  # $2 = question
  # $3 = default value
  # not using read -i because that doesn't work on MacOS
  local ANSWER
  read -r -p "$2 ($3) > " ANSWER
  if [[ -z "$ANSWER" ]] ; then
    eval "$1=\"$3\""
  else
    eval "$1=\"$ANSWER\""
  fi
}

error_prefix="${col_red}>${col_reset}"
trap "die \"ERROR \$? after \$SECONDS seconds \n\
\${error_prefix} last command : '\$BASH_COMMAND' \" \
\$(< \$script_install_path awk -v lineno=\$LINENO \
'NR == lineno {print \"\${error_prefix} from line \" lineno \" : \" \$0}')" INT TERM EXIT
# cf https://askubuntu.com/questions/513932/what-is-the-bash-command-variable-good-for
# trap 'echo ‘$BASH_COMMAND’ failed with error code $?' ERR
safe_exit() { 
  [[ -n "${tmp_file:-}" ]] && [[ -f "$tmp_file" ]] && rm "$tmp_file"
  trap - INT TERM EXIT
  debug "$script_basename finished after $SECONDS seconds"
  exit 0
}

is_set()       { [[ "$1" -gt 0 ]]; }
is_empty()     { [[ -z "$1" ]] ; }
is_not_empty() { [[ -n "$1" ]] ; }

is_file() { [[ -f "$1" ]] ; }
is_dir()  { [[ -d "$1" ]] ; }

show_usage() {
  out "Program: ${col_grn}$script_basename $script_version${col_reset} by ${col_ylw}$script_author${col_reset}"
  out "Updated: ${col_grn}$prog_modified${col_reset}"

  echo -n "Usage: $script_basename"
   list_options \
  | awk '
  BEGIN { FS="|"; OFS=" "; oneline="" ; fulltext="Flags, options and parameters:"}
  $1 ~ /flag/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-10s: [flag] %s [default: off]",$2,$3,$4) ;
    oneline  = oneline " [-" $2 "]"
    }
  $1 ~ /option/  {
    fulltext = fulltext sprintf("\n    -%1s|--%s <%s>: [optn] %s",$2,$3,"val",$4) ;
    if($5!=""){fulltext = fulltext "  [default: " $5 "]"; }
    oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /secret/  {
    fulltext = fulltext sprintf("\n    -%1s|--%s <%s>: [secr] %s",$2,$3,"val",$4) ;
      oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /param/ {
    if($2 == "1"){
          fulltext = fulltext sprintf("\n    %-10s: [parameter] %s","<"$3">",$4);
          oneline  = oneline " <" $3 ">"
     } else {
          fulltext = fulltext sprintf("\n    %-10s: [parameters] %s (1 or more)","<"$3">",$4);
          oneline  = oneline " <" $3 " …>"
     }
    }
    END {print oneline; print fulltext}
  '
}

show_tips(){
  < "${BASH_SOURCE[0]}" grep -v "\$0" \
  | awk "
  /TIP: / {\$1=\"\"; gsub(/«/,\"$col_grn\"); gsub(/»/,\"$col_reset\"); print \"*\" \$0}
  /TIP:> / {\$1=\"\"; print \" $col_ylw\" \$0 \"$col_reset\"}
  "
}

init_options() {
	local init_command
    init_command=$(list_options \
    | awk '
    BEGIN { FS="|"; OFS=" ";}
    $1 ~ /flag/   && $5 == "" {print $3 "=0; "}
    $1 ~ /flag/   && $5 != "" {print $3 "=\"" $5 "\"; "}
    $1 ~ /option/ && $5 == "" {print $3 "=\"\"; "}
    $1 ~ /option/ && $5 != "" {print $3 "=\"" $5 "\"; "}
    ')
    if [[ -n "$init_command" ]] ; then
        #debug "init_options: $(echo "$init_command" | wc -l) options/flags initialised"
        eval "$init_command"
   fi
}

verify_programs(){
  os_name=$(uname -s)
  os_version=$(uname -v)
  debug "Running: on $os_name ($os_version)"
  list_programs=$(echo "$*" | sort -u |  tr "\n" " ")
  debug "Verify : $list_programs"
  for prog in "$@" ; do
    # shellcheck disable=SC2230
    if [[ -z $(which "$prog") ]] ; then
      die "$script_basename needs [$prog] but this program cannot be found on this [$os_name] machine"
    fi
  done
}

folder_prep(){
  if [[ -n "$1" ]] ; then
      local folder="$1"
      local max_days=${2:-365}
      if [[ ! -d "$folder" ]] ; then
          debug "Create folder : [$folder]"
          mkdir "$folder"
      else
          debug "Cleanup folder: [$folder] - delete files older than $max_days day(s)"
          find "$folder" -mtime "+$max_days" -type f -exec rm {} \;
      fi
  fi
}

expects_single_params(){
  list_options | grep 'param|1|' > /dev/null
  }
expects_multi_param(){
  list_options | grep 'param|n|' > /dev/null
  }

parse_options() {
    if [[ $# -eq 0 ]] ; then
       show_usage >&2 ; safe_exit
    fi

    ## first process all the -x --xxxx flags and options
    #set -x
    while true; do
      # flag <flag> is savec as $flag = 0/1
      # option <option> is saved as $option
      if [[ $# -eq 0 ]] ; then
        ## all parameters processed
        break
      fi
      if [[ ! $1 = -?* ]] ; then
        ## all flags/options processed
        break
      fi
	  local save_option
      save_option=$(list_options \
        | awk -v opt="$1" '
        BEGIN { FS="|"; OFS=" ";}
        $1 ~ /flag/   &&  "-"$2 == opt {print $3"=1"}
        $1 ~ /flag/   && "--"$3 == opt {print $3"=1"}
        $1 ~ /option/ &&  "-"$2 == opt {print $3"=$2; shift"}
        $1 ~ /option/ && "--"$3 == opt {print $3"=$2; shift"}
        $1 ~ /secret/ &&  "-"$2 == opt {print $3"=$2; shift"}
        $1 ~ /secret/ && "--"$3 == opt {print $3"=$2; shift"}
        ')
        if [[ -n "$save_option" ]] ; then
          if echo "$save_option" | grep shift >> /dev/null ; then
            local save_var
            save_var=$(echo "$save_option" | cut -d= -f1)
            debug "Found  : ${save_var}=$2"
          else
            debug "Found  : $save_option"
          fi
          eval "$save_option"
        else
            die "cannot interpret option [$1]"
        fi
        shift
    done

    ((help)) && (
      echo "### USAGE"
      show_usage
      echo ""
      echo "### SCRIPT AUTHORING TIPS"
      show_tips
      safe_exit
    )

    ## then run through the given parameters
  if expects_single_params ; then
    single_params=$(list_options | grep 'param|1|' | cut -d'|' -f3)
    list_singles=$(echo "$single_params" | xargs)
    single_count=$(echo "$single_params" | wc -w)
    debug "Expect : $single_count single parameter(s): $list_singles"
    [[ $# -eq 0 ]] && die "need the parameter(s) [$list_singles]"

    for param in $single_params ; do
      [[ $# -eq 0 ]] && die "need parameter [$param]"
      [[ -z "$1" ]]  && die "need parameter [$param]"
      debug "Found  : $param=$1"
      eval "$param=\"$1\""
      shift
    done
  else 
    debug "No single params to process"
    single_params=""
    single_count=0
  fi

  if expects_multi_param ; then
    #debug "Process: multi param"
    multi_count=$(list_options | grep -c 'param|n|')
    multi_param=$(list_options | grep 'param|n|' | cut -d'|' -f3)
    debug "Expect : $multi_count multi parameter: $multi_param"
    (( multi_count > 1 )) && die "cannot have >1 'multi' parameter: [$multi_param]"
    (( multi_count > 0 )) && [[ $# -eq 0 ]] && die "need the (multi) parameter [$multi_param]"
    # save the rest of the params in the multi param
    if [[ -n "$*" ]] ; then
      debug "Found  : $multi_param=$*"
      eval "$multi_param=( $* )"
    fi
  else 
    multi_count=0
    multi_param=""
    [[ $# -gt 0 ]] && die "cannot interpret extra parameters"
  fi
}

lookup_script_data(){
  readonly script_prefix=$(basename "${BASH_SOURCE[0]}" .sh)
  readonly script_basename=$(basename "${BASH_SOURCE[0]}")
  readonly execution_day=$(date "+%Y-%m-%d")
  #readonly execution_year=$(date "+%Y")

   if [[ -z $(dirname "${BASH_SOURCE[0]}") ]]; then
    # script called without path ; must be in $PATH somewhere
    # shellcheck disable=SC2230
    script_install_path=$(which "${BASH_SOURCE[0]}")
    if [[ -n $(readlink "$script_install_path") ]] ; then
      # when script was installed with e.g. basher
      script_install_path=$(readlink "$script_install_path") 
    fi
    script_install_folder=$(dirname "$script_install_path")
  else
    # script called with relative/absolute path
    script_install_folder=$(dirname "${BASH_SOURCE[0]}")
    # resolve to absolute path
    script_install_folder=$(cd "$script_install_folder" && pwd)
    if [[ -n "$script_install_folder" ]] ; then
      script_install_path="$script_install_folder/$script_basename"
    else
      script_install_path="${BASH_SOURCE[0]}"
      script_install_folder=$(dirname "${BASH_SOURCE[0]}")
    fi
    if [[ -n $(readlink "$script_install_path") ]] ; then
      # when script was installed with e.g. basher
      script_install_path=$(readlink "$script_install_path") 
      script_install_folder=$(dirname "$script_install_path")
    fi
  fi
  debug "Executable: [$script_install_path]"
  debug "In folder : [$script_install_folder]"

  [[ -f "$script_install_folder/VERSION.md" ]] && script_version=$(cat "$script_install_folder/VERSION.md")
}

prep_log_and_temp_dir(){
  tmp_file=""
  log_file=""
  # shellcheck disable=SC2154
  if is_not_empty "$tmp_dir" ; then
    folder_prep "$tmp_dir" 1
    tmp_file=$(mktemp "$tmp_dir/$execution_day.XXXXXX")
    debug "tmp_file: $tmp_file"
    # you can use this teporary file in your program
    # it will be deleted automatically if the program ends without problems
  fi
  # shellcheck disable=SC2154
  if [[ -n "$log_dir" ]] ; then
    folder_prep "$log_dir" 7
    log_file=$log_dir/$script_prefix.$execution_day.log
    debug "log_file: $log_file"
    echo "$(date '+%H:%M:%S') | [$script_basename] $script_version started" >> "$log_file"
  fi
}

import_env_if_any(){
  if [[ -f "$script_install_folder/.env" ]] ; then
    debug "Read config from [$script_install_folder/.env]"
    # shellcheck disable=SC1090
    source "$script_install_folder/.env"
  fi
  if [[ -f "./.env" ]] ; then
    debug "Read config from [./.env]"
    # shellcheck disable=SC1091
    source "./.env"
  fi
}

[[ $run_as_root == 1  ]] && [[ $UID -ne 0 ]] && die "user is $USER, MUST be root to run [$script_basename]"
[[ $run_as_root == -1 ]] && [[ $UID -eq 0 ]] && die "user is $USER, CANNOT be root to run [$script_basename]"

lookup_script_data

# set default values for flags & options
init_options

# overwrite with .env if any
import_env_if_any

# overwrite with specified options if any
parse_options "$@"

# run main program
main

# exit and clean up
safe_exit
