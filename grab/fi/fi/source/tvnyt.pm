# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: source specific grabber code for http://tv.nyt.fi
#
###############################################################################
#
# Setup
#
# VERSION: $Id: tvnyt.pm,v 2.02 2011/10/10 16:38:57 stefanb2 Exp $
#
# INSERT FROM HERE ############################################################
package fi::source::tvnyt;
use strict;
use warnings;

BEGIN {
  our $ENABLED = 1;
}

use Carp;

# Import from internal modules
fi::common->import();

# Description
sub description { 'tv.nyt.fi' }

# Grab channel list
sub channels {
  my %channels;
  my @groups = ( "free_air_fi" );
  my $added;

  # Next group
  while (defined(my $group = shift(@groups))) {

    # Fetch & parse HTML
    my $root = fetchTree("http://tv.nyt.fi/home/tvnyt_grid/?group=$group");
    if ($root) {

      #
      # Group list can be found in dropdown
      #
      #  <select id="group_select" ...>
      #    <option value="tvnyt*today*free_air_fi" selected>...</option>
      #    <option value="tvnyt*today*sanoma_fi">...</option>
      #    ...
      #  </select>
      #
      unless ($added) {
	if (my $container = $root->look_down("id" => "group_select")) {
	  if (my @options = $container->find("option")) {
	    debug(2, "Source tv.nyt.fi found " . scalar(@options) . " groups");
            foreach my $option (@options) {
	      unless ($option->attr("selected")) {
		my $value = $option->attr("value");

		if (defined($value) &&
		    (my($tag) = ($value =~ /^tvnyt\*today\*(\w+)$/))) {
		  debug(3, "group '$tag'");
		  push(@groups, $tag);
		}
	      }
	    }
	  }
	}
	$added++;
      }

      #
      # Channel list can be found in table headers
      #
      #  <table class="grid_table" cellspacing="0px">
      #    <thead>
      #      <tr>
      #        <th class="yle_tv1">...</th>
      #        <th class="yle_tv2">...</th>
      #        ...
      #      </tr>
      #    </thead>
      #    ...
      #  </table>
      #
      if (my $container = $root->look_down("class" => "grid_table")) {
	my $head = $container->find("thead");
	if ($head && (my @headers = $head->find("th"))) {
	  debug(2, "Source tv.nyt.fi found " . scalar(@headers) . " channels in group '$group'");
	  foreach my $header (@headers) {
	      if (my $image = $header->find("img")) {
		my $name = $image->attr("alt");
		my $channel_id = $header->attr("class");

		if (defined($channel_id) && length($channel_id) &&
		    defined($name)       && length($name)) {
		  debug(3, "channel '$name' ($channel_id)");
		  $channels{"${channel_id}.${group}.tv.nyt.fi"} = "fi $name";
		}
	      }
	    }
	}
      }

      # Done with the HTML tree
      $root->delete();
    }

  }

  debug(2, "Source tv.nyt.fi parsed " . scalar(keys %channels) . " channels");
  return(\%channels);
}

# Grab one day
sub grab {
  my($self, $id, $yesterday, $today, $tomorrow, $offset) = @_;

  # Get channel number from XMLTV id
  return unless my($channel, $group) = ($id =~ /^(\w+)\.(\w+)\.tv\.nyt\.fi$/);

  return;
}

# That's all folks
1;
