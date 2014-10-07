#!/bin/bash
#set -o nounset

PROGNAME=$(basename $0)
SETUP_APP=./setup.sh
BASE_DIR=$HOME/public/phedex

function usage
{
  cat <<EOF
Usage: $PROGNAME <options>
where options are:
  -s|--se         Site SE (D=T2_IT_Pisa)
  -t|--site       Site name (D=Pisa)
  -v|--verbose    Turn on debug statements (D=false)
  -h|--help       This message

  example: $PROGNAME --site Pisa --se T2_IT_Pisa --verbose
EOF

  exit 1
}

# Initialise, get the disk name
site=Pisa
se=T2_IT_Pisa
let "verbose = 0"

while [ $# -gt 0 ]; do
  case $1 in
    -s | --se )            shift
                           se=$1
                           ;;
    -t | --site )          shift
                           site=$1
                           ;;
    -v | --verbose )       let "verbose = 1"
                           ;;
    -h | --help )          usage
                           ;;
     * )                   usage
                           ;;
  esac
  shift
done

HTML_FILE=./$site.html

cd $BASE_DIR/status || { echo $PROGNAME. Failed to changed directory!; exit 1; }
[ -r $SETUP_APP ] || { echo $PROGNAME. $SETUP_APP not present!; exit 2; }
source $SETUP_APP

tmplfile="file.tmpl"
echo $se | grep -E '^T1_' > /dev/null
[ $? -eq 0 ] && tmplfile="file_T1.tmpl"
echo perl -w parser.pl --output=$HTML_FILE --se=$se --template=$tmplfile
perl -w parser.pl --output=$HTML_FILE --se=$se --template=$tmplfile
exit $?
