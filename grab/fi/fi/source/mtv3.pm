# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: source specific grabber code for http://www.mtv3.fi
#
###############################################################################
#
# Setup
#
# VERSION: $Id: mtv3.pm,v 1.999 yyyy/mm/dd hh:mm:ss xxx Exp $
#
# INSERT FROM HERE ############################################################
package fi::source::mtv3;
use strict;
use warnings;

BEGIN {
  our $ENABLED = 1;
}

# Import from internal modules
fi::common->import();

# Description
sub description { 'mtv3.fi' }

# Grab channel list
sub channels {
  my %channels;

  # Fetch & parse HTML
  my $root = fetchTree("http://www.mtv3.fi/tvopas/", "iso-8859-1");
  if ($root) {

    #
    # Channel list can be found from this dropdown:
    #
    # <select onchange="window.open(this.options[this.selectedIndex].value,'_self')">
    #  <option value="#">Valitse kanava</option>
    #  <option value="/tvopas/index.shtml">YLE1</option>
    #  ...
    #  <option value="/tvopas/muutkanavat.shtml">KinoTV</option>
    #  <option value="/tvopas/muutkanavat.shtml">Digiviihde</option>
    # </select>
    #
    if (my $container = $root->look_down("onchange" => qr/^window.open/)) {
      if (my @options = $container->find("option")) {
	my $count;
	my $oldpage = "";

	debug(2, "Source mtv3.fi found " . scalar(@options) . " channels");
	foreach my $option (@options) {
	  my $id   = $option->attr("value");
	  my $name = $option->as_text();

	  if (defined($id) &&
	      (my($page) = ($id =~ m,^/tvopas/(\w+)\.shtml$,)) &&
	      length($name)) {
	    if ($page ne $oldpage) {
	      $count   = 0;
	      $oldpage = $page;
	    }
	    $count++;
	    debug(3, "channel '$name' (${count}.${page})");
	    $channels{"${count}.${page}.mtv3.fi"} = "fi $name";
	  }
	}
      }
    }

    # Done with the HTML tree
    $root->delete();
  }

  debug(2, "Source mtv3.fi parsed " . scalar(keys %channels) . " channels");
  return(\%channels);
}

# Grab one day
sub grab {
  my($self, $id, $yesterday, $today, $tomorrow) = @_;

  # Get channel number from XMLTV id
  return unless my($channel, $page) = ($id =~ /^(\d+)\.([^.]+)\.mtv3\.fi$/);

  # Fetch & parse HTML
  my $root = fetchTree("http://www.mtv3.fi/tvopas/${page}.shtml/$today");
  if ($root) {

    # Done with the HTML tree
    $root->delete();
  }

  return;
}

# That's all folks
1;
