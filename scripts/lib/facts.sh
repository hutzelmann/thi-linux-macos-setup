#!/usr/bin/env sh
# Read documented values from facts/*.yaml.
#
# Scripts must never hardcode a hostname or queue name: the pages and the checks
# read the same file, so a rename is one edit. Parsing is deliberately dumb:
# the files are one level deep by contract (AGENTS.md), which keeps this
# dependency-free. No yq, no python, works on a stock macOS shell.

facts_dir() {
  # Resolve relative to this file so callers can run from anywhere.
  d=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
  while [ "$d" != "/" ]; do
    if [ -d "$d/facts" ]; then
      printf '%s\n' "$d/facts"
      return 0
    fi
    d=$(dirname "$d")
  done
  echo "facts/ not found above $0" >&2
  return 1
}

# fact <domain> <key>: print the value, fail loudly if absent.
fact() {
  _domain="$1"
  _key="$2"
  _file="$(facts_dir)/${_domain}.yaml" || return 1

  if [ ! -f "$_file" ]; then
    echo "No such facts file: ${_file}" >&2
    return 1
  fi

  _value=$(sed -n "s/^${_key}:[[:space:]]*//p" "$_file" | head -1 |
    sed 's/^"\(.*\)"$/\1/; s/[[:space:]]*$//')

  if [ -z "$_value" ]; then
    echo "No value for ${_domain}.${_key} in ${_file}" >&2
    return 1
  fi

  printf '%s\n' "$_value"
}
