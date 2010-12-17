# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: source specific grabber code for http://www.yle.fi
#
###############################################################################
#
# Setup
#
# INSERT FROM HERE ############################################################
package fi::source::yle;
use strict;
use warnings;

# Import from internal modules
fi::common->import();

# Description
sub description { 'yle.fi' }

# Grab channel list
sub channels {

  # Fetch & parse HTML
  my $root = fetchTree("http://ohjelmaopas.yle.fi/");
  if ($root) {
    my %channels;

    #
    # Channel list can be found from this dropdown:
    #
    # <select name="week" id="viikko_dropdown" class="dropdown">
    #   <option value="">Valitse kanava</option>
    #   <option value="tv1">YLE TV1</option>
    #   ...
    #   <option value="tvf">TV Finland (CET)</option>
    # </select>
    #
    if (my $container = $root->look_down("id" => "viikko_dropdown")) {
      if (my @options = $container->find("option")) {
	debug(2, "Source yle.fi found " . scalar(@options) . " channels");
	foreach my $option (@options) {
	  my $id   = $option->attr("value");
	  my $name = $option->as_text();

	  if (defined($id) && length($id) && length($name)) {
	    debug(3, "channel '$name' ($id)");
	    $channels{"${id}.yle.fi"} = $name;
	  }
	}
      }
    }

    # Done with the HTML tree
    $root->delete();

    debug(2, "Source yle.fi parsed " . scalar(keys %channels) . " channels");
    return(\%channels);
  }

  return;
}

# Grab one day
sub grab {
  my($self, $id, $yesterday, $today, $tomorrow) = @_;

  # Get channel number from XMLTV id
  return unless my($channel) = ($id =~ /^(\S+)\.yle\.fi$/);

  return;
}


# That's all folks
1;

__END__
yle.fi channel list?

yle.fi example URL: http://ohjelmaopas.yle.fi/?groups=tv1&d=20101215

yle.fi HTML::TreeBuilder based parser:

#!/usr/bin/perl -w
use 5.008;
use strict;
use warnings;

use HTML::TreeBuilder;

# Parse HTML
die "usage: $0 <html file>\n" unless @ARGV;
my $html;
{
  local $/;
  open(my $fh, "<:utf8", $ARGV[0]) or die "$0: can't open file '$ARGV[0]': $!\n";
  $html = <$fh>;
  close($fh);
}
my $root = HTML::TreeBuilder->new_from_content($html)
  or die "$0: HTML parsing failed!\n";

binmode(STDOUT, ":utf8");

# programme data
if (my @programmes = $root->look_down("class" => qr/^programme\s+/)) {
    print "FIRST: ", scalar(@programmes), " programmes\n";
    foreach my $programme (@programmes) {
      my $start = $programme->look_down("class", "start");
      my $title = $programme->look_down("class", "desc_title");
      my $desc  = $programme->look_down("class", "desc");
      my $span  = $programme->look_down("class", "desc_time");

      if ($start && $title && $desc && $span) {
    my $start = join("", $start->content_list());
    my $title = join("", $title->content_list());
    my $span  = join("", $span->content_list());

    # Extract text elements from desc (why is this so complicated?)
    my $desc = join("", grep { not ref($_) } $desc->content_list());
    $desc =~ s/^\s+//;
    $desc =~ s/\s+$//;

    if (($start =~ /^\d{2}.\d{2}/) &&
        (my($stop) = $span =~ /\s+$start\s+-\s+(\d{2}.\d{2})/) &&
        defined($title)) {
      print "Programme ($start - $stop) $title: $desc\n";
    }
      }
    }
  }

# Done with the HTML tree
$root->delete();

# That's all folks...
exit 0;
