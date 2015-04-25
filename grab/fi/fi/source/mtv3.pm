# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: source specific grabber code for http://www.mtv3.fi
#
###############################################################################
#
# Setup
#
# VERSION: $Id: mtv3.pm,v 2.04 2013/11/20 07:58:21 stefanb2 Exp $
#
# INSERT FROM HERE ############################################################
package fi::source::mtv3;
use strict;
use warnings;

use Carp;
use HTML::Entities qw(decode_entities);
use JSON;

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
  my $root = fetchTree("http://www.mtv.fi/tvopas#desktop");
  if ($root) {

    #
    # Haven't figured out yet how to grab the channel list...
    #
    # Return hard-coded list for now.
    %channels = (
	"Ava.mtv3.fi"         => "fi Ava",
	"MTV3.mtv3.fi"        => "fi MTV3",
	"MTV-Fakta.mtv3.fi"   => "fi MTV Fakta",
	"MTV-Juniori.mtv3.fi" => "fi MTV Juniori",
	"MTV-Leffa.mtv3.fi"   => "fi MTV Leffa",
	"MTV-Max.mtv3.fi"     => "fi MTV Max",
	"MTV-Sport-1.mtv3.fi" => "fi MTV Sport 1",
	"MTV-Sport-2.mtv3.fi" => "fi MTV Sport 2",
	"Sub.mtv3.fi"         => "fi Sub",
    );

    # Done with the HTML tree
    $root->delete();
  }

  debug(2, "Source mtv3.fi parsed " . scalar(keys %channels) . " channels");
  return(\%channels);
}

# Parse time and convert to seconds since midnight
sub _toEpoch($$) {
  my($day, $time) = @_;
  my($hour, $minute) = ($time =~ /^(\d{2}):(\d{2})$/);
  return(timeToEpoch($day, $hour, $minute));
}

# Grab one day
sub grab {
  my($self, $id, $yesterday, $today, $tomorrow, $offset) = @_;

  # Get channel number from XMLTV id
  return unless my($channel) = ($id =~ /^([^.]+)\.mtv3\.fi$/);

  # Replace Dash with Space for node search
  $channel =~ s/-/ /g;

  # Fetch JSON as raw file. Unfortunately for days without data this fails
  # instead of returning an empty string, so we need to set the "nofail" flag.
  my $content = fetchRaw("http://www.mtv.fi/asset/data/kanavaopas/tvopas-${today}-lite.json",
			 undef, 1);
  if (length($content)) {
     my $parser = JSON->new();
     my $data   = eval {
	 $parser->decode($content)
     };
     croak "JSON parse error: $@" if $@;
     undef $parser;

     #
     # Program information is encoded in JSON:
     #
     # [
     #   {
     #     "age_rating": "S",
     #     "channel": "MTV Juniori",
     #     "end_time": 1430019000,
     #     "episode_age_rating": "S",
     #     "flag_hd": false,
     #     "flag_katsomo": true,
     #     "flag_live": false,
     #     "flag_subtitling": false,
     #     "name": "Hopla",
     #     "progkey": "2684446132812",
     #     "program_type": null,          (elokuvat, urheilu, uutiset, ???)
     #     "start_time": 1430017200
     #    },
     #
     # Verify top-level of data structure
     if ((ref($data) eq "ARRAY")     &&
	 (@{$data} > 0)              &&
	 (ref($data->[0]) eq "HASH")) {
       my @objects;

       foreach my $entry (grep { $_->{channel} eq $channel }
			  @{ $data }) {
	 my $start = $entry->{start_time};
	 my $stop  = $entry->{end_time};
	 my $title = decode_entities($entry->{name});
	 #my $desc  = decode_entities($entry->{desc}); ???

	 # Sanity check
	 if (($start > 0) &&
	     ($stop  > 0) &&
	     length($title)) {
	   my $category = $entry->{program_type};

	   debug(3, "List entry $channel ($start -> $stop) $title");
	   #debug(4, $desc);
	   debug(4, $category) if defined $category;

	   # Create program object
	   my $object = fi::programme->new($id, "fi", $title, $start, $stop);
	   #$object->description($desc);
	   $object->category($category);
	   push(@objects, $object);
	 }
       }

       # Fix overlapping programmes
       fi::programme->fixOverlaps(\@objects);

       return(\@objects);
     }
  }

  return;
}

# That's all folks
1;
