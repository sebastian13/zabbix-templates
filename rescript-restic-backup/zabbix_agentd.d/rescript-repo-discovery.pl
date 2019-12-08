#!/usr/bin/perl -w

$base = $ARGV[0];

# List all files ending in .conf
opendir(DIR, $base) || die "cannot open directory: $!";
@repos = grep { /\.conf$/ } readdir(DIR);
closedir(DIR);

# Remove .conf to get the repo name
for (@repos) { s/.conf//; }

$first = 1;

print "{\"data\":[";

for (@repos)
{
    print "," if !$first;
    print "{\"{#REPO}\":\"$_\"}";
    $first = 0;
}

print "]}";
