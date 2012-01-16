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
  return;
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
