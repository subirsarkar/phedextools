BASEDIR=$HOME/workspace/public/phedextools
if [ -n "$PERL5LIB" ]; then
  echo $PERL5LIB | grep $BASEDIR/lib > /dev/null
  [ $? -eq 0 ] || export PERL5LIB=$BASEDIR/lib:$PERL5LIB
else
  export PERL5LIB=$BASEDIR/lib
fi
export PERL5LIB=/afs/cern.ch/cms/LCG/crab/perl/lib/perl5/site_perl/5.8.8/:$PERL5LIB
