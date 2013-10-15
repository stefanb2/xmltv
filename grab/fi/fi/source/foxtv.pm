# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: source specific grabber code for http://www.foxtv.fi
#
###############################################################################
#
# Setup
#
# VERSION: $Id: telkku.pm,v 1.999 yyyy/mm/dd hh:mm:ss xxx Exp $
#
# INSERT FROM HERE ############################################################
package fi::source::foxtv;
use strict;
use warnings;

BEGIN {
  our $ENABLED = 1;
}

# Import from internal modules
fi::common->import();
fi::programmeStartOnly->import();

# Description
sub description { 'foxtv.fi' }

# Grab channel list - only one channel available, no need to fetch anything...
sub channels { { 'foxtv.fi' => 'fi FOX' } }

# Grab one day
sub grab {
  my($self, $id, $yesterday, $today, $tomorrow, $offset) = @_;

  # Get channel number from XMLTV id
  return unless ($id eq "foxtv.fi");

  #
  # Only the weekly page contains all the information we need. Each of the 7
  # days in a week will return the same weekly information, although the URL
  # will be different. This will break XMLTV caching.
  #
  # The weekly page starts on Monday. We simply calculate what the Monday of
  # the week is that contains the day we want to grab.
  #
  my $wday;
  my $url;
  {
    # Epoch of today at 12:00
    my $epoch = timeToEpoch($today, 12, 0);

    # localtime weekday: 0: Sunday, 1: Monday,  ..., 6: Saturday
    # foxtv.fi weekday:  0: Monday, 1: Tuesday, ..., 6: Sunday
    $wday = ((localtime($epoch))[6] + 6) % 7;

    # Epoch of today (if it is Monday) or the previous Monday, at
    # 11:00 if Monday (standard time) -> today (daylight saving time)
    # 12:00 if no daylight saving change during the week
    # 13:00 if Monday (daylight saving time) -> today (standard time)
    my($mday, $mon, $year) = (localtime($epoch - $wday * 86400))[3..5];
    $mon  += 1;
    $year += 1900;

    # URL for weekly page
    $url = "http://www.foxtv.fi/ohjelmat/weekly/$mday.$mon.$year";
  }

  # Fetch & parse HTML
  my $root = fetchTree($url);
  if ($root) {
    my $opaque = startProgrammeList();

    #
    # All program info is contained in a table column *without* class
    #
    #  <table class="bloque-slider">
    #   <tr>
    #    <td class="calendarHours">      [Index 0]
    #    ... one list item per hour ...
    #    </td>
    #    <td>                            [Index 1: Monday -> $wday + 1]
    #      <div class="itemListings halfHour  ">
    #        <a href=... rel="colorbox">
    #          ...
    #          <span>00:55</span>
    #          ...
    #        </a>
    #        <div id="ShowDetailsOverlay" class="ShowDetails ">
    #          ...
    #          <div class="Content">
    #            <h4>Low Winter Sun</h4>
    #            ...
    #            <div class="Details colLeft">
    #              <h5 class="ShowTitle colLeft">Tuotantokausi 1</h5>
    #              <h5 class="ShowTitle colLeft">
    #                  Jakso 10
    #              </h5>
    #              <p>sunnuntain myöhäisilloissa </p>
    #              ...
    #            </div>
    #            <div class="ShowDescription colLeft">Murhien, petosten, koston ja korruption värittämän modernin draamasarjan päähenkilönä on etsivä Frank Agnew.</div>
    #            ...
    #          </div>
    #        </div>
    #      </div>
    #    </td>
    #    <td>                            [Index 2: Tuesday]
    #    ...
    #   </tr>
    #  </table>
    #
    if (my $container = $root->look_down("class" => "bloque-slider")) {
      if (my @table_entries = $container->find("td")) {
	if (my @programmes = $table_entries[$wday + 1]->look_down("class" => qr/^itemListings/)) {
	  foreach my $programme (@programmes) {
            my $start   = $programme->look_down("rel" => "colorbox");
	    my $details = $programme->look_down("class" => "Content");

	    if ($start && $details) {
	      my $desc  = $details->look_down("class" => "ShowDescription colLeft");
	      my $title = $details->find("h4");
	      $start = $start->find("span");

	      if ($desc && $title && $start) {
		if (my($hour, $minute) =
		    $start->as_text() =~ /^(\d{2}):(\d{2})/) {
		  my($season, $episode_number) = $programme->look_down("class" => "ShowTitle colLeft");
		  my $episode_name             = $programme->find("p");

		  $title = $title->as_text();
		  $desc  = $desc->as_text();

		  # Description can be empty or "-"
		  undef $desc if ($desc eq '') || ($desc eq '-');

		  # Season, episode number & episode name (optional)
		  ($season)         = ($season->as_text() =~ /(\d+)/)
		    if $season;
		  ($episode_number) = ($episode_number->as_text() =~ /(\d+)/)
		    if $episode_number;
		  ($episode_name)   = ($episode_name->as_text() =~ /^\s*(.+)\s*$/)
		    if $episode_name;

		  debug(3, "List entry fox ($hour:$minute) $title");
		  debug(4, $episode_name) if defined $episode_name;
		  debug(4, $desc)         if defined $desc;
		  debug(4, sprintf("s%02de%02d", $season, $episode_number))
		    if (defined($season) && defined($episode_number));

		  appendProgramme($opaque, $hour, $minute, $title, undef, $desc);
		}
	      }
	    }
	  }
	}
      }
    }

    # Done with the HTML tree
    $root->delete();

    return(convertProgrammeList($opaque, $id, "fi", $yesterday, $today, $tomorrow));
  }

  return;
}

# That's all folks
1;
