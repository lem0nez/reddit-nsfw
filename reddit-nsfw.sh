#!/usr/bin/env bash

# Copyright © 2019 Nikita Dudko. All rights reserved.
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

TMP_FILE=$(mktemp -ut 'tmp.reddit-nsfw_XXXXXX')
cleanup() {
  rm -f "$TMP_FILE"
}
trap cleanup EXIT

RED=197
BLUE=33
GRAY=250
OUT_BOLD='\x1b[1m'
OUT_RESET='\x1b[0m'

GPG_PASS='nsfw'
FAVOURITES_FILE="reddit-nsfw_favourites.list"

main() {
  if [[ -z $1 ]]; then
    show_help
    exit 0
  fi

  while [[ -n $1 ]]; do
    case $1 in
      -r|--rank)
        check_pattern "$2"
        search "^[^|]*$2[^|]*\\|" 'ranks'
        shift && shift ;;
      -s|--subscribers)
        check_pattern "$2"
        search "^[^|]+\\|[^|]*$2[^|]*\\|" 'number of subscribers'
        shift && shift ;;
      -u|--url)
        check_pattern "$2"
        search "^[^|]+\\|[^|]+\\|[^|]*$2[^|]*\\|" 'URLs'
        shift && shift ;;
      -t|--title)
        check_pattern "$2"
        search "\\|[^|]*$2[^|]*\\|[^|]*$" 'titles'
        shift && shift ;;
      -d|--description)
        check_pattern "$2"
        search "\\|[^|]*$2[^|]*$" 'descriptions'
        shift && shift ;;
      -f|--favourites)
        if [[ ${2::1} != '-' ]]; then
          pattern=$2
          shift
        fi

        show_favourites "$pattern"
        shift ;;
      -a|--add)
        add_favourite "$2"
        shift && shift ;;
      -e|--exclude)
        exclude_favourite "$2"
        shift && shift ;;
      -c|--case-sensitive)
        CASE_SENSITIVE=true
        shift ;;
      -h|--help)
        show_help
        exit 0 ;;
      -*)
        printf >&2 "Unrecognized parameter: $OUT_BOLD%s$OUT_RESET!\\n" "$1"
        exit 1 ;;
      *)
        search "$1"
        shift ;;
    esac
  done
}

# First parameter — a pattern.
# Second parameter (not necessary) — a search place.
search() {
  printf "Searching for the pattern results"
  if [[ ! -z $2 ]]; then
    printf " in $OUT_BOLD%s$OUT_RESET" "$2"
  fi
  echo '...'

  if [[ $CASE_SENSITIVE != true ]]; then
    insensitive_par='-i'
  fi

  get_list |
      grep --color=never --no-group-separator -B 0 -A 0 $insensitive_par -E "$1" |
      sed -r "s/^([^|]+)\\|([^|]+)\\|([^|]+)\\|([^|]+)\\|([^|]*)$/"`
      `" $OUT_BOLD$(get_col $RED)--- --- --- ---$OUT_RESET\\n"`
      `"$(get_col $GRAY)Rank: $(get_col $BLUE)\\1\\n"`
      `"$(get_col $GRAY)Subscribers:$OUT_RESET \\2\\n"`
      `"$(get_col $GRAY)URL:$OUT_RESET www.reddit.com\\/\\3\\n"`
      `"$(get_col $GRAY)Title:$OUT_RESET $OUT_BOLD\\4$OUT_RESET\\n"`
      `"$(get_col $GRAY)Description:$OUT_RESET \\5/"
  CASE_SENSITIVE=false
}

show_favourites() {
  favourites=$(tr '\n' '|' < "$(get_favourites_path)")

  if [[ -z $favourites ]]; then
    echo >&2 'No favourite subreddits!'
    exit 1
  fi

  search "^($favourites)\\|.*$1" 'favourites'
}

# First parameter — a rank.
add_favourite() {
  check_rank "$1"
  favourites_path=$(get_favourites_path)

  if [[ -n $(grep -E "^$1$" < "$favourites_path") ]]; then
    printf >&2 "Subreddit with the rank $(get_col $BLUE)%i$OUT_RESET "`
        `"already in the list!\\n" "$1"
    exit 1
  fi

  title=$(get_list | grep --color=never -B 0 -A 0 -E "^$1\\|" |
      awk -F '|' '{print $4}')

  if [[ -z $title ]]; then
    printf >&2 "Subreddit with the rank $(get_col $BLUE)%i$OUT_RESET "`
        `"didn't exist!\\n" "$1"
    exit 1
  fi

  echo "$1" >> "$favourites_path"
  printf "Subreddit \"$OUT_BOLD%s$OUT_RESET\" added to the favourites list.\\n" `
      `"$title"
}

# First parameter — a rank.
exclude_favourite() {
  check_rank "$1"
  favourites_path=$(get_favourites_path)

  if [[ -z $(grep -E "^$1$" < "$favourites_path") ]]; then
    printf >&2 "Subreddit with the rank $(get_col $BLUE)%i$OUT_RESET "`
        `"not in the favourites list!\\n" "$1"
    exit 1
  fi

  sed -i -r "/^$1$/d" "$favourites_path"
  title=$(get_list | grep --color=never -B 0 -A 0 -E "^$1\\|" |
      awk -F '|' '{print $4}')

  printf "Subreddit \"$OUT_BOLD%s$OUT_RESET\" "`
      `"excluded from the favourites list.\\n" "$title"
}

show_help() {
  printf "Usage: ${OUT_BOLD}reddit-nsfw${OUT_RESET} [parameters] <pattern> ...\\n"`
      `"\\nSearch place:\\n"`
      `"  ${OUT_BOLD}-r, --rank${OUT_RESET}           ranks;\\n"`
      `"  ${OUT_BOLD}-s, --subscribers${OUT_RESET}    number of subscribers;\\n"`
      `"  ${OUT_BOLD}-u, --url${OUT_RESET}            URLs;\\n"`
      `"  ${OUT_BOLD}-t, --title${OUT_RESET}          titles;\\n"`
      `"  ${OUT_BOLD}-d, --description${OUT_RESET}    descriptions.\\n"`
      `"\\nFavourites:\\n"`
      `"  ${OUT_BOLD}-f, --favourites [pattern]${OUT_RESET}    "`
          `"show favourites;\\n"`
      `"  ${OUT_BOLD}-a, --add <rank>${OUT_RESET}              "`
          `"add subreddit to the favourites;\\n"`
      `"  ${OUT_BOLD}-e, --exclude <rank>${OUT_RESET}          "`
          `"exclude subreddit from the favourites.\\n"`
      `"\\nOther parameters:\\n"`
      `"  ${OUT_BOLD}-c, --case-sensitive${OUT_RESET}    case sensitive "`
          `"(by default is case insensitive);\\n"`
      `"  ${OUT_BOLD}-h, --help${OUT_RESET}              show help.\\n"
}

# First parameter — color code.
get_col() {
  printf '\x1b[38;5;%dm' "$1"
}

# Return newest subreddits list.
get_list() {
  if [[ ! -e $TMP_FILE ]]; then
    lists_path="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lists"
    echo "$GPG_PASS" | gpg --batch --passphrase-fd 0 -o "$TMP_FILE" `
        `"$lists_path/$(ls -r1 "$lists_path" | head -1)" &> /dev/null

    if [[ ! -e $TMP_FILE ]]; then
      echo >&2 "Can't decrypt a list file!"
      exit 1
    fi
  fi
  cat "$TMP_FILE"
}

check_pattern() {
  if [[ -z $1 || ${1::1} == '-' ]]; then
    echo >&2 'Please, specify a pattern!'
    exit 1
  fi
}

check_rank() {
  if [[ ! $1 =~ ([0-9]+) ]]; then
    echo >&2 'Please, specify a rank!'
    exit 1
  fi
}

get_favourites_path() {
  if [[ -z $XDG_CONFIG_HOME ]]; then
    XDG_CONFIG_HOME="$HOME/.config"
  fi

  if [[ ! -e $XDG_CONFIG_HOME/$FAVOURITES_FILE ]]; then
    mkdir -p "$XDG_CONFIG_HOME"
    touch "$XDG_CONFIG_HOME/$FAVOURITES_FILE"
  fi

  echo "$XDG_CONFIG_HOME/$FAVOURITES_FILE"
}

main "$@"
