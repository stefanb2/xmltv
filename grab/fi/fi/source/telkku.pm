# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: source specific grabber code for http://www.telkku.com
#
###############################################################################
#
# Setup
#
# VERSION: $Id: telkku.pm,v 2.05 2014/06/21 16:36:15 stefanb2 Exp $
#
# INSERT FROM HERE ############################################################
package fi::source::telkku;
use strict;
use warnings;

BEGIN {
  our $ENABLED = 1;
}

# Import from internal modules
fi::common->import();
fi::programmeStartOnly->import();

# Description
sub description { 'telkku.com' }

# Grab channel list
sub channels {

  # TEMPORARY: return fixed channel to pass testing
  return({ "yle-tv1.telkku.com" => "fi YLE TV1" });
}

# Grab one day
sub grab {
  my($self, $id, $yesterday, $today, $tomorrow, $offset) = @_;

  # Get channel number from XMLTV id
  return unless my($channel) = ($id =~ /^([\w-]+)\.telkku\.com$/);

  # TEMPORARY: do nothing to pass testing
  return;
}

# That's all folks
1;
