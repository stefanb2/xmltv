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
use strict;
use warnings;

use JSON;

# Import from internal modules
fi::common->import();

# Description
sub description { 'tvnyt.fi' }

# Copied from Javascript code. No idea why we should do this...
sub _timestamp() {
  return("timestamp=" . int(rand(10000)));
}

# Grab channel list
sub channels {

  # Fetch JavaScript code as raw file
  my $content = fetchRaw("http://www.tvnyt.fi/ohjelmaopas/wp_channels.js?" . _timestamp());
  if (length($content)) {
    my $count = 0;
    # 1) pattern match JS arrays (example: ["1","TV1","tv1.gif"] -> 1, "TV1")
    # 2) even entries in the list are converted to XMLTV ID
    # 3) fill hash from list (even -> key [id], odd -> value [name])
    my %channels = (
		    map { ($count++ % 2) == 0 ? "$_.tvnyt.fi" : $_ }
		      $content =~ /\["(\d+)","([^\"]+)","[^\"]+"\]/g
		   );
    debug(2, "Source tvnyt.fi parsed " . scalar(keys %channels) . " channels");
    return(\%channels);
  }

  return;
}

# Grab one day
sub grab {
  my($self, $id, $yesterday, $today, $tomorrow) = @_;

  # Get channel number from XMLTV id
  return unless my($channel) = ($id =~ /^(\d+)\.tvnyt\.fi$/);

  return;
}

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
