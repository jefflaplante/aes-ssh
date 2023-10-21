#! /bin/bash

MODE="e"
RSA_KEY=""
FILE_IN=""

function usage() { 
  echo "Usage: $0 -d [ -p RSA_KEY ] [ -f FILE_TO_(EN|DE)CRYPT ]" 1>&2
  exit 0
}

function check_pkcs8() {
  if [ -f "$1" ]; then
    grep -q -e "^-----BEGIN PUBLIC KEY-----$" $1
    if [ ! $? -eq 0 ]; then
      echo "Error - Public key is not pkcs8 format"
      exit 2
    fi
  else
    exit 3
  fi
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

  # Check for file
  if [ ! -f "$PUB_KEY" ]
  then
    echo "File does not exist: $PUB_KEY"
    exit 3
  fi

  check_pkcs8 $PUB_KEY

  if [ ! -f "$FILE_TO_ENCRYPT" ]
  then
    echo "Files does not exist: $FILE_TO_ENCRYPT"
    exit 4
  fi

  # Create temp key
  openssl rand -out $KEY 32

  # Encrypt file with temporary key
  openssl aes-256-cbc -in $FILE_TO_ENCRYPT -out $FILE_ENCRYPTED -pass file:$KEY -pbkdf2
  if [ $? -eq 0 ] 
  then 
    echo "encrypted file with $KEY" 
  else 
    echo "error encrypting file" >&2
    rm $KEY
    exit 86
  fi

  # Encrypt key with ssh public key
  openssl pkeyutl -encrypt -pubin -inkey $PUB_KEY -in $KEY -out $KEY_ENCRYPTED
  if [ $? -eq 0 ] 
  then 
    echo "encrypted $KEY_ENCRYPTED with $1" 
  else 
    echo "error encrypting $KEY" >&2
    rm $KEY
    exit 64 
  fi

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

