#! /bin/bash

MODE="e"
RSA_KEY=""
FILE_IN=""

function usage() { 
  echo "Usage: $0 -d [ -p RSA_KEY ] [ -f FILE_TO_(EN|DE)CRYPT ]" 1>&2
  exit 0
}

function encrypt() {
  # Create UUID
  UUID=$(uuidgen)
  KEY="key-$UUID"
  KEY_ENCRYPTED="$KEY.enc"

  # PUB KEY
  PUB_KEY=$1

  # FILE
  FILE_TO_ENCRYPT=$2
  FILE_ENCRYPTED=$FILE_TO_ENCRYPT.$UUID.enc

  # Create temp key
  openssl rand -out $KEY 32

  # Encrypt file with temporary key
  openssl aes-256-cbc -in $FILE_TO_ENCRYPT -out $FILE_ENCRYPTED -pass file:$KEY -pbkdf2

  # Encrypt key with ssh public key
  openssl pkeyutl -encrypt -pubin -inkey $PUB_KEY -in $KEY -out $KEY_ENCRYPTED

  # Remove temp key
  rm $KEY
  
  echo "Public Key Used: $PUB_KEY"
  echo "Encrypted Key:   $KEY_ENCRYPTED"
  echo "Encrypted File:  $FILE_ENCRYPTED"
}

function decrypt() {
  echo "decrypt needs to be implemented still..."  
}

while getopts "hdp:f:" options; do
  case "${options}" in
    h)
      usage
      ;;
    d)
      MODE="d"
      ;;
    p)
      RSA_KEY=${OPTARG}
      ;;
    f)
      FILE_IN=${OPTARG}
      ;;
    :)
      echo "Error: -${OPTARG} requires an argument"
      exit 1
      ;;
    *)
      exit 99
      ;;
  esac
done

if [ "$MODE" = "e" ]; then
  encrypt $RSA_KEY $FILE_IN
fi

if [ "$MODE" = "d" ]; then
  decrypt $RSA_KEY $FILE_IN
fi

exit 0

