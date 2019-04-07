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
# Subreddits are locating on following address:
# https://www.reddit.com/r/nsfw411/wiki/fulllist{num},
# where {num} is number of page (starts from 1).
#
# The output list have following format:
# Rank | Subscribers | Link | Title | Description

main() {
  if [[ -z $1 ]]; then
    echo >&2 'Specify at least one HTML file!'
    exit 1
  fi

  while [[ -n $1 ]]; do
    if [[ ! -f $1 ]]; then
      echo >&2 "File \"$1\" didn't exist!"
      exit 1
    fi

    input=$(cat "$1" | tr '\n' '\r' |
        sed -r 's#^.+</thead><tbody>\r##; s#</tbody></table>\r.+$##')

    echo -n "$input" | sed -r 's#'`
        `'<tr>\r<td>([0-9]+)</td>\r'` # Rank
        `'<td>[^>]+>([^<]+)</a></td>\r'` # URL
        `'<td>[^>]+>([0-9,]+)</a></td>\r'` # Subscribers
        `'<td>([^\r]+)</td>\r'` # Title
        `'<td>([^\r]*)</td>\r</tr>\r'` # Description
        `'#\1|\3|\2|\4|\5\n#g; '`
        `'s#<[^>]+>##g; s/&#39;/'"'"'/g; s#&gt;#>#g; s#&lt;#<#g; s#&amp;#\&#g'
    shift
  done
}

main "$@"
