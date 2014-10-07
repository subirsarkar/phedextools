#!/bin/sh
#set -o nounset

PROGNAME=$(basename $0)
cd $HOME/public/phedex/status || { echo ERROR. Failed to cd to $HOME/phedex_status; exit 1; }

JSONFILE=./sites.json
#TARFILE=./siteinfo.tar
WEBDIR=/afs/cern.ch/work/s/sarkar/public/phedex

SETUP_APP=./setup.sh
source $SETUP_APP

sites=($(perl -w cms_sites.pl $JSONFILE 2>/dev/null))
let "nsites = ${#sites[@]}"
[ $nsites -gt 0 ] || { echo CMS sites not found! exit 2; }

#rm -f $TARFILE.gz
#tar -cvf $TARFILE $JSONFILE

for se in ${sites[*]}
do
  echo ">> Processing $se"
  ./publish.sh --site $se --se $se
  file=$se.html
#  [ -r $file ] && tar -rvf $TARFILE $file && rm $file
  [ -r $file ] && mv $file $WEBDIR/
done

#gzip -9 $TARFILE
exit $?
