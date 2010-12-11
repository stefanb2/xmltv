#!/usr/bin/perl -w
#
# Merger to generate tv_grab_fi
#
use 5.008;
use strict;
use warnings;

use File::Basename;

# working directory
my $dir = dirname($0);

# output file
open(my $ofh, ">", "$dir/tv_grab_fi")
  or die "can't open output file: $!";

# source modules
my @sources = sort <$dir/fi/source/*.pm>;
print "Found source modules: ", map({ basename($_) . " " } @sources), "\n";

# open main script
open(my $ifh, "<", "$dir/tv_grab_fi.pl")
  or die "can't open main script file: $!";

# Merge
while (<$ifh>) {

  # insert marker for source modules
  if (/^# INSERT: SOURCES/) {

      foreach my $source (@sources) {
	open(my $sfh, "<", $source)
	  or die "can't open source module '$source': $!";
	print "Inserting source module '", basename($source), "'\n";
	while (<$sfh>) {
	  next if 1../^# INSERT FROM HERE /;
	  print $ofh $_;
	}
	close($sfh);
	print $ofh "###############################################################################\n";
      }

  # insert marker for source modules
  } elsif (/^# CUT CODE START/../^# CUT CODE END/) {

  # normal line
  } else {
    print $ofh $_;
  }
}

# check for write errors
close($ofh)
  or die "error while writing to output file: $!";

# set executable flag
chmod(0755, "$dir/tv_grab_fi");

# That's all folks...
print "Merge done.\n";
exit 0;
