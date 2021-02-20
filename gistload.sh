#!/usr/bin/env bash

username=$1
gitdir=$2

function usage {
  echo "Usage: gistload.sh <git-username> <dir>"
  exit 1
}

function ensureRepoClean {
  if [ ! -d "$gitdir/.git" ]; then return 1; fi
  if ! which git > /dev/null; then return 1; fi

  if [ -n "$(git -C "$gitdir" status --porcelain)" ]; then
    echo "$gitdir repo has uncommitted changes, exiting to not break anything"
    exit 1
  else
    return 0
  fi
}

function main {
  mkdir -p "$gitdir" && cd "$gitdir" || exit 1

  echo "Downloading gists files to $gitdir"
  githubResp=$(curl -s -f --tlsv1.2 -H "Accept: application/vnd.github.v3+json" "https://api.github.com/users/$username/gists")
  if [ $? -ne 0 ]; then
    echo "Could not load gist list. Is $username a real github user?"
    exit 1
  fi

  echo "Found $(echo "$githubResp" | jq ". | length") gists for $username (files count might be larger)"
  counter=0
  for json in $(echo "$githubResp" | jq -r ".[].files[] | {file:.filename, url:.raw_url} | @base64"); do
    decoded=$(echo "$json" | base64 --decode)
    originalFilename=$(echo "$decoded" | jq -r ".file")
    url=$(echo "$decoded" | jq -r ".url")
    filename="$(echo "$url" | sha256sum | head -c 4)_$originalFilename"

    sleep 1

    curl -s -f --tlsv1.2 --connect-timeout 5 -o "$filename" "$url"
    if [ $? -ne 0 ]; then
      echo "error downloading $url"
      exit 1
    fi

    ((counter += 1))
    echo -ne "Downloaded $counter file(s)\r"
  done

  if [ "$counter" -eq 0 ]; then
    exit
  fi

  echo "Downloaded $counter file(s)"
}

if [ -z "$username" ] || [ -z "$gitdir" ]; then
  usage
fi

if [ -f "$gitdir" ]; then
  echo "$gitdir exists and is regular file, should be a directory instead"
  exit 1
fi

if [ -d "$gitdir" ] && [ -n "$(ls -a "$gitdir")" ]; then
  if ensureRepoClean; then
    main
  else
    echo "$gitdir is not empty, its content might get overwritten, proceed?"
    select yn in "Yes" "No"; do
      case $yn in
      Yes)
        main
        break
        ;;
      No) exit 0 ;;
      esac
    done
  fi
else
  main
fi
