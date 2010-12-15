# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: source specific grabber code for http://www.tvnyt.fi
#
###############################################################################
#
# Setup
#
# INSERT FROM HERE ############################################################
package fi::source::tvnyt;

use JSON;

# Description
sub description { 'tvnyt.fi' }

# That's all folks
1;

__END__

example channel URL

   http://www.tvnyt.fi/ohjelmaopas/getChannelPrograms.aspx?channel=1&start=201012180000&timestamp=0

  timestamp: random number between 0 and 9999? (check javascript code)


#!/usr/bin/perl -w
use 5.008;
use strict;
use warnings;

use HTML::Entities qw(decode_entities);
use JSON qw();

# Parse JSON
die "usage: $0 <json file>\n" unless @ARGV;
my $json;
{
  local $/;
  open(my $fh, "<:utf8", $ARGV[0]) or die "$0: can't open file '$ARGV[0]': $!\n";
  $json = <$fh>;
  close($fh);
}

my $parser = JSON->new();
# Accept "x:.." instead of the correct "'x':..."
$parser->allow_barekey();
my $data = eval {
  $parser->decode($json)
};
die "$0: JSON parse error: $@\n" if $@;

binmode(STDOUT, ":utf8");

# programme data
if ((exists $data->{1}) && (ref($data->{1}) eq "ARRAY")) {
  my $programmes = $data->{1};
  print "FOUND ", scalar(@{ $programmes }), " programmes\n";
  foreach my $programme (@{ $programmes }) {
    my $start = $programme->{start};
    my $stop  = $programme->{stop};
    my $title = decode_entities($programme->{title});
    my $desc  = decode_entities($programme->{desc});
    if (defined($start) && defined($stop) && defined($title)) {
      print "Programme ($start -> $stop) $title: $desc\n";
    }
  }
}

# That's all folks...
exit 0;
