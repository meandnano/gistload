# gistload

A script used to download public gists of a given GitHub user

### Usage

```gistload.sh <github-username> <dir>```

All files for all the user's gists will be downloaded into the specified directory. Downloaded file name will include the original file name plus a portion of
sha256 sum of its url in the form of:
`<4bytes-of-hash>_<originalname>`, for instance `shah_originalFile.txt`

In case target dir exists, is a git repo and contains unstaged changes, downloading will be aborted.

### Requirements

- bash 4+
- git
- jq
- curl