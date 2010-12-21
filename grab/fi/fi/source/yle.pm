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
fi::programmeStartOnly->import();

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

  # Fetch & parse HTML
  my $root = fetchTree("http://ohjelmaopas.yle.fi/?groups=$channel&d=$today");
  if ($root) {

    #
    # Each programme can be found in a separate <div> node
    #
    # The class is a combination of
    #     programme - literal
    #     clear     - encryption?
    #    (onair)    - this programme is currently on the air
    #     catN      - category type?
    #
    #  <div class="programme clear  onair cat1" style="">
    #    <div class="start">18.00</div>
    #    <div class="title">
    #      <a href="?show=tv1201012151800" class="programmelink" id="link_tv11800">Kuuden Tv-uutiset ja sää</a>
    #    </div><br />
    #    <div class="desc" id="desc_tv11800">
    #      <span class="desc_title">Kuuden Tv-uutiset ja sää</span>
    #      <span class="desc_time">
    #        YLE TV1        18.00 -
    #        18.30
    #      </span>
    #      Mukana talous kulttuuri ja urheilu.<br />
    #      <a ...</a>
    #    </div>
    #  </div>
    #
    # - first entry always starts on $today
    # - last entry always ends on $tomorrow
    # - the end time in "desc_time" is unfortunately unreliable and leads to
    #   overlapping programme entries.
    #
    my $opaque = startProgrammeList();
    if (my @programmes = $root->look_down("class" => qr/^programme\s+/)) {

      foreach my $programme (@programmes) {
	my $start = $programme->look_down("class", "start");
	my $title = $programme->look_down("class", "desc_title");
	my $desc  = $programme->look_down("class", "desc");

	if ($start && $title && $desc) {
	  my $start = join("", $start->content_list());
	  my $title = join("", $title->content_list());

	  # Extract text elements from desc (why is this so complicated?)
	  my $desc = join("", grep { not ref($_) } $desc->content_list());
	  $desc =~ s/^\s+//;
	  $desc =~ s/\s+$//;

	  # Sanity checks
	  if ((my($hour, $minute) = ($start =~ /^(\d{2}).(\d{2})/)) &&
	      length($title)) {
	    debug(3, "List entry $channel ($start:$minute) $title");
	    debug(4, $desc);

	    # Add programme
	    appendProgramme($opaque, $hour, $minute, $title, $desc);
	  }
	}
      }
    }

    # Done with the HTML tree
    $root->delete();

    # Convert list to program objects
    return(convertProgrammeList($opaque, $id, $yesterday, $today, $tomorrow));
  }

  return;
}

# That's all folks
1;
