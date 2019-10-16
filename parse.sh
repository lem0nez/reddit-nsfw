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


# This script parse HTML files with subreddits and print a formatted list.
#
# Subreddits are locating on the following address:
# https://www.reddit.com/r/NSFW411/wiki/fulllist{num}?show_source,
# where {num} is number of page (starts from 1).
# Old pages didn't use "show_source" flag.
#
# The output list have following format:
# Rank | Subscribers | Link | Title | Description

main() {
  if [[ -z $1 ]]; then
    show_help
    exit 1
  fi

  while [[ -n $1 ]]; do
    if [[ ${1:0:1} == '-' ]]; then
      if [[ $1 != '--use-old-pattern' ]]; then
        echo >&2 "Unrecognized parameter: $1!"
        show_help
        exit 1
      else
        use_old_pattern=true
        shift
        continue
      fi
    elif [[ ! -f $1 ]]; then
      echo >&2 "File \"$1\" doesn't exist!"
      exit 1
    fi

    if [[ $use_old_pattern ]]; then
      pattern='s#^.+</thead><tbody>\r##; s#</tbody></table>\r.+$##; s#'`
          `'<tr>\r<td>([0-9]+)</td>\r'` # Rank
          `'<td>[^>]+>([^<]+)</a></td>\r'` # URL
          `'<td>[^>]+>([0-9,]+)</a></td>\r'` # Subscribers
          `'<td>([^\r]+)</td>\r'` # Title
          `'<td>([^\r]*)</td>\r</tr>\r'` # Description
          `'#\1|\3|\2|\4|\5\n#g;'`
          `'s#<[^>]+>##g; s/&#39;/'"'"'/g; s#&gt;#>#g; s#&lt;#<#g; s#&amp;#\&#g'
    else
      pattern='s/.+\|--\r(.+)\r\*.+/\1/; s/=\r//g; s/'`
          `'([0-9]+)\|'` # Rank
          `'([^|]+)\|'` # URL
          `'([0-9]+)\|'` # Subscribers
          `'[^|]+\|([^\r]+)\r/'` # Title
          `'\1|\3|\2|\4|\n/g;'`
          `'s/\\\*//g; s/\\#/#/g; s/\\\^/^/g; s/\\`/`/g; s/=[0-9A-F]{2}//g;'`
          `'s/&amp;/\&/g; s/&amp;/\&/g; s/&gt;/>/g; s/&lt;/</g;'`
          `'s/(\|[[:blank:]]+|[[:blank:]]+\|)/|/g'
    fi

    tr '\n' '\r' < "$1" | sed -r "$pattern"
    shift
  done

  exit 0
}

show_help() {
  script_name=$(basename "$(readlink -f "$0")")
  echo >&2 "Usage: $script_name [--use-old-pattern] <HTML files...>."
}

main "$@"
