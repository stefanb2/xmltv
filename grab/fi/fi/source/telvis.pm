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
