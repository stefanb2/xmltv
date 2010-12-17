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

use Time::Local qw(timelocal);

# Import from internal modules
fi::common->import();

# Description
sub description { 'telkku.com' }

# Take a day (day/month/year) and the program start time (hour/minute)
# and convert it to seconds since Epoch in the current time zone
sub _program_time_to_epoch($$) {
  my($date, $program) = @_;
  return(timelocal(0, $program->{minute}, $program->{hour},
		   $date->day(), $date->month() - 1, $date->year()));
}

# Grab channel list
sub channels {
  # Do nothing for now...
  return;
}

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
    my @programmes;
    if (my $container = $root->look_down("class" => "programList")) {
      if (my @list = $container->find("li")) {
	foreach my $list_entry (@list) {
	  my $date = $list_entry->look_down("class", "programDate");
	  my $desc = $list_entry->look_down("class", "programDescription");
	  if ($date && $desc) {
	    my $href = $date->find("a");
	    if ($href) {

	      # Extract texts from HTML elements. Entities are already decoded.
	      $date = $href->as_text();
	      $desc = $desc->as_text();

	      # Use "." to match &nbsp; character (it's not included in \s?)
	      if (my($hour, $minute, , $title) =
		  $date =~ /^(\d{2}):(\d{2}).(.+)/) {
		debug(3, "List entry $channel ($hour:$minute) $title");
		debug(4, $desc);

		# Only record entry if title isn't empty
		push(@programmes, {
				   description => $desc,
				   hour        => $hour,
				   minute      => $minute,
				   # minutes since midnight
				   start       => $hour * 60 + $minute,
				   title       => $title,
				  })
		  if length($title) > 0;
	      }
	    }
	  }
	}
      }
    }

    # Done with the HTML tree
    $root->delete();

    # No data found -> return empty list
    return unless @programmes;

    # Each page on telkku.com contains the program information
    # for one channel for one whole day.
    #
    # Example (compiled from several pages for illustration):
    #
    #  /- start time             (day)
    #  |     /- program title
    #  |     |
    # [23:45 Uutisikkuna         (yesterday)]
    #  00:10 Uutisikkuna         (today    )
    #  ...
    #  23:31 Uusi päivä          (today    )
    #  00:00 Kova laki           (tomorrow )
    # [00:40 Piilosana           (tomorrow )]
    # [01:00 Tellus-tietovisa    (tomorrow )]
    #
    # The lines in [] don't appear on every page.
    #
    # Check for day crossing between first and second entry
    my @dates = ($today, $tomorrow);
    unshift(@dates, $yesterday)
      if ((@programmes > 1) &&
	  ($programmes[0]->{start} > $programmes[1]->{start}));


    my @objects;
    my $date          = shift(@dates);
    my $current       = shift(@programmes);
    my $current_start = $current->{start};
    my $current_epoch = _program_time_to_epoch($date, $current);
    foreach my $next (@programmes) {

      # Start of next program might be on the next day
      my $next_start = $next->{start};
      $date          = shift(@dates)
	if $current_start > $next_start;
      my $next_epoch = _program_time_to_epoch($date, $next);

      # Create program object
      debug(3, "Programme $id ($current_epoch -> $next_epoch) $current->{title}");
      my $object = fi::programme->new($id, $current->{title},
				      $current_epoch, $next_epoch);
      $object->description($current->{description});
      push(@objects, $object);

      # Move to next program
      $current       = $next;
      $current_start = $next_start;
      $current_epoch = $next_epoch;
    }

    return(\@objects);
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
