# Copyright © 2018 Nikita Dudko. All rights reserved.
# Contacts: <nikita.dudko.95@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/usr/bin/env bash

COLOR_GRAY='\x1b[38;5;250m'
COLOR_BLUE='\x1b[38;5;33m'
COLOR_RED='\x1b[38;5;197m'
TEXT_BOLD='\x1b[1m'
TEXT_RESET='\x1b[0m'

ENCRYPTED_TAR='lists_29-08-2016.tar.enc'
TMP_TAR='.lists.tar.tmp'
TMP_DIR='.lists.tmp'
GPG_PASSPHRASE='nsfw'
SED_DIVIDER='@'

DIVIDER=" $TEXT_BOLD$COLOR_RED--- --- --- ---$TEXT_RESET\\n"
SED_PATTERN="s/(.+)\|(.+)\|(.+)\|(.*)\|(.*)/$DIVIDER"`
    `"${COLOR_GRAY}Rank:$TEXT_RESET \1\\n"`
    `"${COLOR_GRAY}Subscribers:$TEXT_RESET \3\\n"`
    `"${COLOR_GRAY}URL:$TEXT_RESET \2\\n"`
    `"${COLOR_GRAY}Title:$TEXT_RESET $TEXT_BOLD\4$TEXT_RESET\\n"`
    `"${COLOR_GRAY}Description:$TEXT_RESET \5/"

main() {
  parse_params $@
  curr_path="$(pwd)"

  if [[ ! -e "$curr_path/$ENCRYPTED_TAR" ]]; then
    echo 'Encrypted archive with lists of subreddits not exist!'
    exit 1
  fi

  start_time=$(date +%s)

  printf "Searching for \"$COLOR_BLUE$PATTERN$TEXT_RESET\""
  if [[ -n $SEARCH_PLACE ]]; then
    printf " in $TEXT_BOLD$SEARCH_PLACE$TEXT_RESET"
  fi
  printf "...\n"

  rm -f "$curr_path/$TMP_TAR"
  echo "$GPG_PASSPHRASE" | gpg --batch --passphrase-fd 0 `
      `-o "$curr_path/$TMP_TAR" -d "$curr_path/$ENCRYPTED_TAR" &> /dev/null

  rm -rf "$curr_path/$TMP_DIR"
  mkdir "$curr_path/$TMP_DIR"
  tar -xf "$curr_path/$TMP_TAR" -C "$curr_path/$TMP_DIR"
  rm -f "$curr_path/$TMP_TAR"

  for file in $curr_path/$TMP_DIR/*; do
    if [[ -n $SEARCH_PATTERN ]]; then
      pattern_swp="$(echo "$SEARCH_PATTERN" |
      sed -r "s$SED_DIVIDER\{PATTERN\}$SED_DIVIDER$PATTERN$SED_DIVIDER")"
          cat "$file" | grep -E $CASE_INSENSITIVE -B 0 -A 0 --color=never `
          `"$pattern_swp" | sed -r "$SED_HIGHLIGHT_PATTERN; $SED_PATTERN"
    else
      cat "$file" | grep -E $CASE_INSENSITIVE -B 0 -A 0 --color=never `
          `"$PATTERN" | sed -r "$SED_PATTERN"
    fi
  done

  printf "${DIVIDER}Search finished in "`
      `"$TEXT_BOLD$(( $(date +%s) - $start_time ))$TEXT_RESET s.\n"
  rm -rf "$curr_path/$TMP_DIR"
}

parse_params() {
  if [[ -z $1 ]]; then
    show_help
    exit 1
  fi

  while [[ -n $1 ]]; do
    key=$1
    case $key in
      -[a-z]*)
        for (( i = 1; i < ${#key}; ++i )); do
          param=${key:$i:1}
          case $param in
            r)
              SEARCH_PLACE='ranks'
              SEARCH_PATTERN='^[^|]*{PATTERN}[^|]*\|.+$'
              SED_HIGHLIGHT_PATTERN="s/^([^|]+)\|(.+)$/$COLOR_BLUE\1|\2/" ;;
            s)
              SEARCH_PLACE='number of subscribers'
              SEARCH_PATTERN='^[^|]+\|[^|]+\|[^|]*{PATTERN}[^|]*\|.+$'
              SED_HIGHLIGHT_PATTERN=`
                  `"s/^([^|]+)\|([^|]+)\|([^|]+)\|(.+)$/\1|\2|$COLOR_BLUE\3|\4/" ;;
            u)
              SEARCH_PLACE='URLs'
              SEARCH_PATTERN='^[^|]+\|[^|]*{PATTERN}[^|]*\|.+$'
              SED_HIGHLIGHT_PATTERN=`
                  `"s/^([^|]+)\|([^|]+)\|(.+)$/\1|$COLOR_BLUE\2|\3/" ;;
            t)
              SEARCH_PLACE='titles'
              SEARCH_PATTERN='^.+\|[^|]*{PATTERN}[^|]*\|[^|]*$'
              SED_HIGHLIGHT_PATTERN=`
                  `"s/^(.+)\|([^|]*)\|([^|]*)$/\1|$COLOR_BLUE\2|\3/" ;;
            d)
              SEARCH_PLACE='descriptions'
              SEARCH_PATTERN='^.+\|[^|]*{PATTERN}[^|]*$'
              SED_HIGHLIGHT_PATTERN="s/^(.+)\|([^|]*)$/\1|$COLOR_BLUE\2/" ;;
            i)
              CASE_INSENSITIVE='-i' ;;
            h)
              show_help
              exit 0 ;;
            *)
              printf "Invalid parameter: $TEXT_BOLD$key$TEXT_RESET!"
              exit 1 ;;
          esac
        done
        shift ;;
      *)
        PATTERN=$key
        shift ;;
    esac
  done

  if [[ -z $PATTERN ]]; then
    echo 'Please, specify pattern!'
    exit 1
  elif [[ $PATTERN =~ $SED_DIVIDER ]]; then
    echo "Pattern shouldn't contain \"$SED_DIVIDER\" symbol!"
    exit 1
  fi
}

show_help() {
  printf "Usage: reddit-nsfw.sh {parameters} [pattern].\n"`
      `"Search in (only one parameter can be used):\n"`
      `"  $TEXT_BOLD-r$TEXT_RESET  ranks;\n"`
      `"  $TEXT_BOLD-s$TEXT_RESET  number of subscribers;\n"`
      `"  $TEXT_BOLD-u$TEXT_RESET  URLs;\n"`
      `"  $TEXT_BOLD-t$TEXT_RESET  titles;\n"`
      `"  $TEXT_BOLD-d$TEXT_RESET  descriptions.\n"`
      `"Other parameters:\n"`
      `"  $TEXT_BOLD-i$TEXT_RESET  case insensitive;\n"`
      `"  $TEXT_BOLD-h$TEXT_RESET  show help.\n"
}

main $@
