#!/usr/bin/perl -w

# This script identifies Logical Volumes and
# Rescript Repositories configured, to create
# Zabbix Items for every possible combination

# Author: Sebastian Plocek
# https://github.com/sebastian13/zabbix-templates
# https://github.com/sebastian13/lvm-restic-backup

use strict;
use warnings;
use 5.010;

# Save Path to Rescript Config Files
my $home = $ENV{"HOME"};
my $rescript_dir = $home . "/.rescript";
my $config_dir = "$rescript_dir/config";

# Get the names of all Rescript Repositories
opendir(DIR, $config_dir) || die "cannot open directory: $!";
my @repos = grep { /\.conf$/ } readdir(DIR);
closedir(DIR);
# Remove .conf to get the repo name
for (@repos) { s/.conf//; };

# Get the names of all Logical Volumes
# Exclude Snapshots and LV name containing swap or *swp
my @lv_names = `lvs --noheading -o lv_name -S 'lv_attr !~ ^s' | grep -v -e 'swap' -e 'swp' | tr -d '  '`;
# Delete Empty Lines
chomp @lv_names;

my $first = 1;

print "{\"data\":[";

foreach my $repo (@repos) 
{
    foreach my $lv (@lv_names)
    {
    	print "," if !$first;
    	$first = 0;

    	print "{";
    	print "\"{#REPO}\":\"$repo\"";
    	print ",";
    	print "\"{#LV}\":\"$lv\"";
    	print "}";
    }
}

print "]}";
