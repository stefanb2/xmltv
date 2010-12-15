# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: source specific grabber code for http://www.telkku.com
#
###############################################################################
#
# Setup
#
# INSERT FROM HERE ############################################################
package fi::source::telkku;
use strict;
use warnings;

# Import from internal modules
fi::common->import();

# Description
sub description { 'telkku.com' }

# Grab one day
sub grab {
  my($self, $id, $yesterday, $today, $tomorrow) = @_;

  # Get channel number from XMLTV id
  return unless my($channel) = ($id =~ /^(\d+)\.telkku\.com$/);

  # Generate day URL
  my $url = "http://www.telkku.com/channel/list/$channel/$today";

  # Fetch & parse HTML
  my $root = fetchTree($url);
  if ($root) {

    #
    # All program info is contained within a unsorted list with class "programList"
    #
    #  <ul class="programList">
    #   <li>
    #    <span class="programDate"><a href="http://www.telkku.com/program/show/2010112621451">23:45&nbsp;Uutisikkuna</a></span><br />
    #    <span class="programDescription">...</span>
    #   </li>
    #   ...
    #  </ul>
    #
    if (my $container = $root->look_down("class" => "programList")) {
      if (my @programmes = $container->find("li")) {
	foreach my $programme (@programmes) {
	  my $date = $programme->look_down("class", "programDate");
	  my $desc = $programme->look_down("class", "programDescription");
	  if ($date && $desc) {
	    my $href = $date->find("a");
	    if ($href) {

	      # Extract texts from HTML elements. Entities are already decoded.
	      $date = $href->as_text();
	      $desc = $desc->as_text();

	      # Use "." to match &nbsp; character (it's not included in \s?)
	      if (my($start, $title) = $date =~ /^(\d{2}:\d{2}).(.+)/) {
		debug(3, "Programme $channel ($start) $title");
		debug(4, $desc);

		# TBA...
	      }
	    }
	  }
	}
      }
    }

    # Done with the HTML tree
    $root->delete();
  }

  return;
}

# That's all folks
1;

__END__

example URL: http://www.telkku.com/channel/list/1/20101218

telkku HTML::TreeBuilder/Element based parser

#!/usr/bin/perl -w
use 5.008;
use strict;
use warnings;

use HTML::TreeBuilder;

# Parse HTML
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

# channel list
if (my $container = $root->look_down("id" => "channelList")) {
  print "FOUND: ", $container->tag(), "\n";
  if (my @channels = $container->find("li")) {
    print "FIRST: ", scalar(@channels), " channels\n";
    foreach my $channel (@channels) {
      if (my $a = $channel->find("a")) {
    my $href = $a->attr("href");
    my $name = $a->as_text();

    if (defined($href) && ($name ne "") &&
        (my($channel_no) = ($href =~ m,channel/list/(\d+)/,))) {
      print "$name ($channel_no)\n";
    }
      }
    }
  }
}

# Done with the HTML tree
$root->delete();

# That's all folks...
exit 0;
