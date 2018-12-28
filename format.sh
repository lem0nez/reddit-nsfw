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

# This script need to format tables, that contains NSFW subreddits.
# They located on Reddit: www.reddit.com/r/nsfw411/wiki/fulllist{num},
# where {num} - number of page.
#
# After processing output file will be have following format:
# Rank | Link | Subscribers | Title | Description

#!/usr/bin/env bash

URL_PATTERN="[a-zA-Z0-9.,:_-+/!?*=%#$'()]+"
SED_PATTERN='s/^<td>//; s/<\/td>$//; s/<\/a>//g; s/<\/td><td>/|/g; '`
    `'s/<a href="'$URL_PATTERN'" rel="[[:lower:]]+">/www.reddit.com\//; '`
    `'s/<a href="'$URL_PATTERN'" title="[0-9-]+" rel="[[:lower:]]+">//g; '`
    `'s/<a href="'$URL_PATTERN'" rel="[[:lower:]]+">//g; '`
    `'s/<\/?em>//g; s/<\/?del>//g; s/<\/?h4>//g; s/<\/br>//g; '`
    `'s/&gt\;/>/g; s/&lt\;/</g; s/&amp\;/\&/g'

main() {
  echo 'Processing. Please, wait...'

  while read -r line; do
    # Start of list with subscriptions.
    if [[ $line == "</thead><tbody>" ]]; then
      read=true
      cat /dev/null > "$2"
    # End of list with subscriptions.
    elif [[ $line == "</tbody></table>" ]]; then
      echo 'Deleting empty lines...'
      sed -i '/^$/d' "$2"
      # Processing finished!
      exit 0
    elif [[ $read == true ]]; then
      if [[ -n $(echo "$line" | sed -r '/^<.*tr>$/d') ]]; then
        fmt_line="$fmt_line$line"
      else
        echo "$(echo "$fmt_line" | sed -r "$SED_PATTERN")" >> "$2"
        fmt_line=$(cat /dev/null)
      fi
    fi
  done < $1
}

if [[ -z $1 ]]; then
  echo 'Usage: format.sh [input HTML] [output file].'
  exit 1
elif [[ ! -e $1 ]]; then
  echo "File \"$1\" not exist!"
  exit 1
elif [[ -z $2 ]]; then
  echo 'Please, specify output file!'
  exit 1
fi

main $@
