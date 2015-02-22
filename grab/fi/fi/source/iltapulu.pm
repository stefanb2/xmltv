# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: source specific grabber code for http://www.iltapulu.fi
#
###############################################################################
#
# Setup
#
# VERSION: $Id: iltapulu.pm,v 2.07 2014/06/14 18:18:36 stefanb2 Exp $
#
# INSERT FROM HERE ############################################################
package fi::source::iltapulu;
use strict;
use warnings;

#
# NOTE: this data source was earlier known as http://tv.hs.fi
# NOTE: this data source was earlier known as http://tv.tvnyt.fi
#
BEGIN {
  our $ENABLED = 1;
}

use Carp;

# Import from internal modules
fi::common->import();

# Description
sub description { 'iltapulu.fi' }

# Grab channel list
sub channels {
  my %channels;

  # Fetch & parse HTML
  my $root = fetchTree("http://www.iltapulu.fi/?&all=1");
  if ($root) {
    #
    # Channel list can be found in table rows
    #
    #  <table class="channel-row"">
    #   <tbody>
    #    <tr>
    #     <td class="channel-name">...</td>
    #     <td class="channel-name">...</td>
    #     ...
    #    </tr>
    #   </tbody>
    #   ...
    #  </table>
    #
    if (my @tables = $root->look_down("class" => "channel-row")) {
      foreach my $table (@tables) {
	my @cells = $table->look_down("class" => "channel-name");
	foreach my $cell (@cells) {
	  if (my $image = $cell->find("img")) {
	    my $name = $image->attr("alt");
	    $name =~ s/\s+tv-ohjelmat$//;

	    if (defined($name) && length($name)) {
	      my $channel_id = (scalar(keys %channels) + 1) . ".iltapulu.fi";
	      debug(3, "channel '$name' ($channel_id)");
	      $channels{$channel_id} = "fi $name";
	    }
	  }
	}
      }
    }

    # Done with the HTML tree
    $root->delete();
  }

  debug(2, "Source iltapulu.fi parsed " . scalar(keys %channels) . " channels");
  return(\%channels);
}

# Parse time and convert to seconds since midnight
sub _toEpoch($$$$) {
  my($today, $tomorrow, $time, $switch) = @_;
  my($hour, $minute) = ($time =~ /^(\d{2})(\d{2})$/);
  return(timeToEpoch($switch ? $tomorrow : $today, $hour, $minute));
}

# Grab one day
sub grab {
  my($self, $id, $yesterday, $today, $tomorrow, $offset) = @_;

  # Get channel number from XMLTV id
  return unless my($channel, $group) = ($id =~ /^([-\w]+)\.([-\w]+)\.tv\.hs\.fi$/);

  # Replace Dash with Underscore for URL
  $channel =~ s/-/_/g;
  $group   =~ s/-/_/g;

  # Fetch & parse HTML
  my $root = fetchTree("http://tv.hs.fi/home/grid?group=${group}&date=" . $today->ymdd());
  if ($root) {
    my @objects;

    #
    # Programme data is contained inside a table cells with class="<channel>"
    #
    #  <td class="yle_tv1">
    #   <table class="be_list_table">
    #    <tr class="s1210 e1230"> (start/end time, "+" for tomorrow)
    #     <td class="be_time">12:10</td>
    #     <td class="be_entry">
    #      <span class="thb1916041"></span>
    #      <span class="flw6390"></span>
    #      <a href="/programs/show/1916041" class="program_link colorbox tip">
    #       Hercules... (title)
    #      </a>
    #      <span class="tooltip">
    #       <span class="wl_actions">...</span>
    #       <span class="wl_synopsis">
    #        Dokumenttielokuva bulgarialaisen perheen... (long description)
    #       </span>
    #      </span>
    #      <span class="syn">
    #       Dokumenttielokuva bulgarialaisen... (short description)
    #      </span>
    #     </td>
    #    </tr>
    #   ...
    #   </table>
    #  </td>
    #
    if (my @cells = $root->look_down("class" => $channel,
				     "_tag"  => "td")) {
      foreach my $cell (@cells) {
	foreach my $row ($cell->find("tr")) {
	  my $start_stop = $row->attr("class");
	  my $entry      = $row->look_down("class" => "be_entry");
          if (defined($start_stop) && $entry &&
	      (my($start, $stomorrow, $end, $etomorrow) =
	       ($start_stop =~ /^s(\d{4})(\+?)\s+e(\d{4})(\+?)$/))) {
	    my $title = $entry->look_down("class" => qr/program_link/);
            my $desc  = $entry->look_down("class" => "wl_synopsis");
	    if ($title) {
	      $title = $title->as_text();
              if (length($title)) {
		$start = _toEpoch($today, $tomorrow, $start, $stomorrow);
		$end   = _toEpoch($today, $tomorrow, $end,   $etomorrow);
		$desc  = $desc->as_text() if $desc;

		debug(3, "List entry ${channel}.${group} ($start -> $end) $title");
		debug(4, $desc) if $desc;

		# Create program object
		my $object = fi::programme->new($id, "fi", $title, $start, $end);
		$object->description($desc);
		push(@objects, $object);
	      }
	    }
	  }
	}
      }
    }

    # Done with the HTML tree
    $root->delete();

    # Fix overlapping programmes
    fi::programme->fixOverlaps(\@objects);

    return(\@objects);
  }

  return;
}

# That's all folks
1;
