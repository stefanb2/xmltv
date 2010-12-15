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

# Description
sub description { 'telkku.com' }

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
my $container;
if ($container = $root->look_down("id" => "channelList")) {
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

# programme data
if ($container = $root->look_down("class" => "programList")) {
  print "FOUND: ", $container->tag(), "\n";
  if (my @programmes = $container->find("li")) {
    print "FIRST: ", scalar(@programmes), " programmes\n";
    foreach my $programme (@programmes) {
      my $date = $programme->look_down("class", "programDate");
      my $desc = $programme->look_down("class", "programDescription");
      if ($date && $desc) {
	my $href = $date->find("a");
	if (defined($href)) {
	  $date = $href->as_text();
	  $desc = $desc->as_text();
	  # Use "." to match &nbsp; character (it's not included in \s?)
	  if (my($start, $title) = $date =~ /^(\d{2}:\d{2}).(.+)/) {
	    print "Programme ($start) $title: $desc\n";
	  }
	}
      }
    }
  }
}

# Done with the HTML tree
$root->delete();

# That's all folks...
exit 0;
