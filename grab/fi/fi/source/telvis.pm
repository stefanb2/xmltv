# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: source specific grabber code for http://www.telvis.fi
#
###############################################################################
#
# Setup
#
# VERSION: $Id: telvis.pm,v 1.999 yyyy/mm/dd hh:mm:ss xxx Exp $
#
# INSERT FROM HERE ############################################################
package fi::source::telvis;
use strict;
use warnings;

# Import from internal modules
fi::common->import();
fi::programmeStartOnly->import();

# Description
sub description { 'telvis.fi' }

# Grab channel list
sub channels {
  my %channels;

  # Fetch & parse HTML
  my $root = fetchTree("http://www.telvis.fi/tvohjelmat/?vw=channel");
  if ($root) {

    #
    # Channel list can be found in multiple <div> nodes
    #
    # <div class="progs" style="text-align:left;">
    #  <a href="/tvohjelmat/?vw=channel&ch=tv1&sh=new&dy=03.02.2011">YLE TV1</a>
    #  <a href="/tvohjelmat/?vw=channel&ch=tv2&sh=new&dy=03.02.2011">YLE TV2</a>
    #  ...
    # </div>
    #
    if (my @containers = $root->look_down("class" => "progs")) {
      foreach my $container (@containers) {
	if (my @refs = $container->find("a")) {
	  debug(2, "Source telvis.fi found " . scalar(@refs) . " channels");
	  foreach my $ref (@refs) {
	    my $href = $ref->attr("href");
	    my $name = $ref->as_text();

	    if (defined($href) && length($name) &&
		(my($id) = ($href =~ m,vw=channel&ch=([^&]+)&,))) {
	      debug(3, "channel '$name' ($id)");
	      $channels{"${id}.telvis.fi"} = "fi $name";
	    }
	  }
	}
      }
    }

    # Done with the HTML tree
    $root->delete();

  } else {
    return;
  }

  debug(2, "Source telvis.fi parsed " . scalar(keys %channels) . " channels");
  return(\%channels);
}

# Grab one day
sub grab {
  my($self, $id, $yesterday, $today, $tomorrow) = @_;

  # Get channel number from XMLTV id
  return unless my($channel, $language) = ($id =~ /^([^.]+)\.telvis\.fi$/);

  return;
}

# That's all folks
1;
