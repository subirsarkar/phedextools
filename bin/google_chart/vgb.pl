#!/usr/bin/env perl

use strict;
use warnings;
use URI::GoogleChart;

my $chart = URI::GoogleChart->new("horizontal-stacked-bars", 600, 250,
    data => [
              [10,-10,-5,30,15,5,9],
              [2,10,-15,0,10,5,29]
            ],
    margin => 20,
    chf => "c,lg,45,FFE7C6,0,d3d3d3,0.75|b0,lg,0,3072a3,0,ff9696,1|b1,lg,0,3072a3,0,ff0000,1",
    chxt => 'y',
    chxl => '0:|T1_UK_RAL|T1_ES_PIC|T1_DE_KIT|T1_FR_CCIN2P3|T1_US_FNAL|T1_IT_CNAF|T2_TW_ASGC',
    chxs => '0,009ccc,13,-1,_,FF0000',
    range_show => "bottom",
    background => "transparent"
);

# save chart to a file
use LWP::Simple qw(getstore);
getstore($chart, "chart.png");

