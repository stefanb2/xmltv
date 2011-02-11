# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: source specific grabber code for http://www.sub.fi
#
###############################################################################
#
# Setup
#
# VERSION: $Id: sub.pm,v 1.999 yyyy/mm/dd hh:mm:ss xxx Exp $
#
# INSERT FROM HERE ############################################################
package fi::source::sub;
use strict;
use warnings;

BEGIN {
  our $ENABLED = 1;
}

# Import from internal modules
fi::common->import();

# Description
sub description { 'sub.fi' }

# Grab channel list
sub channels { {'sub.fi' => 'fi Sub'}; }

# Grab one day
sub grab {
  my($self, $id, $yesterday, $today, $tomorrow) = @_;

  # Get channel number from XMLTV id
  return unless $id eq 'sub.fi';

  # Fetch & parse HTML
  my $root = fetchTree("http://www.sub.fi/tvopas/paiva.shtml/${today}");
  if ($root) {

    # Done with the HTML tree
    $root->delete();
  }

  return;
}

# That's all folks
1;
