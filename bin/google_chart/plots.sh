#!/bin/bash
set -o nounset

# Current week
today=$(date "+%Y/%m/%d" --date='0 day ago')
wget --quiet http://cms-project-relval.web.cern.ch/cms-project-relval/CustodialSummary/$today/data_acq_output.csv -O data_acq_output.csv
wget --quiet http://cms-project-relval.web.cern.ch/cms-project-relval/CustodialSummary/$today/mc_acq_output.csv -O mc_acq_output.csv
perl -w tape_storage.pl $today

# Last Week
then=$(date "+%Y/%m/%d" --date='7 days ago')
wget --quiet http://cms-project-relval.web.cern.ch/cms-project-relval/CustodialSummary/$then/data_acq_output.csv -O data_acq_output_lw.csv
wget --quiet http://cms-project-relval.web.cern.ch/cms-project-relval/CustodialSummary/$then/mc_acq_output.csv -O mc_acq_output_lw.csv
perl -w delta_tape.pl "$then - $today"

exit 0
