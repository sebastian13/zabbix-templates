#!/usr/bin/perl -w

$first = 1;
$repo = $ENV{'REPO'};
$lv_to_backup = $ENV{'LV_TO_BACKUP'};

# Check provided [lv_name] or list of [lv_names]
if (-f $lv_to_backup) {
	# If a file was provided.
	# print "Path to a file was provided";
	for (`grep -v '^#' $lv_to_backup`)
	{
		# Check each LV existence
		$lvs = "";
		$lvs = `lvs --noheading -o lv_name | grep -ow "$_"`;
		# Remove NewLine from String
		$_ =~ s/\R//g;
		if ($lvs eq "") {print "LV $_ was not found."; exit 1;}
		push @lv_names, $_;
	}
} else {
	# If a string was provided.
	# print "lv_name was provided";
	# Check if LV exists.
	$lvs = `lvs --noheading -o lv_name | grep -ow "$lv_to_backup"`;
	if ($lvs eq "") {print "LV $lv_to_backup was not found."; exit 1;}
	@lv_names = $lv_to_backup;
}

print "{\"data\":[";

for $_ (@lv_names)
{
    print "," if !$first;
    $first = 0;

    print "{";
    print "\"{#REPO}\":\"$repo\",";
    print "\"{#LV}\":\"$_\"";
    print "}";
}

print "]}";