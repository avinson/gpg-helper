#!/bin/bash

usage()
{
cat << EOF
usage: $0 COMMAND [OPTIONS]

This script provides various GPG keychain operations

COMMANDS:
    encrypt_for_all:   encrypt [FILE] for all public keys in [DIR]
    import_and_trust:  import and ultimately trust and sign all public keys in [DIR]
    list_keys:         list public key IDs in [DIR]
    list_fprs:         list public key fingerprints in [DIR]

OPTIONS:
    -h      Show this message
    -d      Set [DIR]ectory to use for key operations. Defaults to '.'
    -f      Set [FILE] for use in encryption operations. Defaults to STDIN
EOF
}

BASEDIR="."
FILE=
OFILE=
KEYRING=
KEYS=
FPRS=

create_keyring()
{
  KEYRING=$(mktemp /tmp/keyring.XXXXXXXXXX) || { echo "Failed to create temp file"; exit 1; }
  
  OUTPUT=`find $BASEDIR -maxdepth 3 -name '*.key' -o -name '*.asc' -o -name '*.txt' -o -name '*.gpg' \
    | xargs gpg --no-default-keyring --keyring $KEYRING --import 2>&1 | egrep 'imported$'`

  KEYS=`gpg --no-default-keyring --keyring $KEYRING --list-keys | perl -n -e'/pub   \w+\/(\w+)/ && print "$1\n"'`
  FPRS=`gpg --no-default-keyring --keyring $KEYRING --list-keys --fingerprint --with-colons | grep fpr | cut -d':' -f10`
  RECIP=`gpg --no-default-keyring --keyring $KEYRING --list-keys | perl -n -e'/pub   \w+\/(\w+)/ && print "-r $1 "'`
}

remove_keyring()
{
  # remove temporary keyring
  rm -f $KEYRING
  rm -f $KEYRING~
}

encrypt_for_all()
{
  gpg --no-default-keyring --keyring $KEYRING --trust-model always -o $FILE.gpg $RECIP -e $FILE
  if [ $? -eq 0 ]; then
    echo; echo "Encrypted $FILE to $FILE.gpg"; echo
  fi
}

import_and_trust()
{
  # import keys to user's personal keychain
  find $BASEDIR -maxdepth 3 -name '*.key' -o -name '*.asc' -o -name '*.txt' \
    | xargs gpg --import 2>&1 | egrep 'imported$'
    
  echo "Trusting keys..."
  echo
  for f in $FPRS; do
    echo "$f:6:" | gpg --import-ownertrust
  done
  echo
  echo "Signing keys..."
  echo
  for k in $KEYS; do
    gpg --batch --yes --sign-key $k 2>&1 | grep "was already signed by"
  done
}

list_keys()
{
  echo "Listing public key IDs in $BASEDIR" 1>&2
  echo 1>&2
  for k in $KEYS; do
    echo $k
  done
}

list_fprs()
{
  echo "Listing public key fingerprints in $BASEDIR" 1>&2
  echo 1>&2
  for k in $FPRS; do
    echo $k
  done
}

COMMAND=$1
shift

while getopts “hd:f:o:” OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    d)
      BASEDIR=$OPTARG
      ;;
    f)
      FILE=$OPTARG
      ;;
  esac
done

# create the temporary keyring and import keys
create_keyring

case $COMMAND in
  encrypt_for_all)
    if [ -z "$FILE" ]; then
      echo "You must specify -f [FILE] with this command"
      exit 1
    fi
    encrypt_for_all
    ;;
  import_and_trust)
    import_and_trust
    ;;
  list_keys)
    list_keys
    ;;
  list_fprs)
    list_fprs
    ;;
  *)
    usage
    ;;
esac

# remove the temporary keyring
remove_keyring

exit 1
