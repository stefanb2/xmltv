# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: programme class
#
###############################################################################
#
# Setup
#
# INSERT FROM HERE ############################################################
package fi::programme;
use strict;
use warnings;
use Carp;
use POSIX qw(strftime);

# Import from internal modules
fi::common->import();

sub _trim {
  return unless defined($_[0]);
  $_[0] =~ s/^\s+//;
  $_[0] =~ s/\s+$//;
}

# Constructor
sub new {
  my($class, $channel, $title, $start, $stop) = @_;
  _trim($title);
  croak "${class}::new called without valid title, start or stop"
    unless defined($channel) && defined($title) && (length($title) > 0) &&
           defined($start) && defined($stop);

  my $self = {
	      channel => $channel,
	      title   => $title,
	      start   => $start,
	      stop    => $stop
	     };

  return(bless($self, $class));
}

# instance methods
sub description {
  my($self, $description) = @_;
  _trim($description);
  $self->{description} = $description
    if defined($description) && (length($description) > 0);
}

# Convert seconds since Epoch to XMLTV time stamp
#
# NOTE: We have to generate the time stamp using local time plus time zone as
#       some XMLTV users, e.g. mythtv in the default configuration, ignore the
#       XMLTV time zone value.
#
sub _epoch_to_xmltv_time($) {
  my($time) = @_;

  # Unfortunately strftime()'s %z is not portable...
  #
  # return(strftime("%Y%m%d%H%M00 %z", localtime($time));
  #
  # ...so we have to roll our own:
  #
  my @time = localtime($time); #               is_dst
  return(strftime("%Y%m%d%H%M00 +0", @time) . ($time[8] ? "3": "2") . "00");
}

sub dump {
  my($self, $writer, $progressbar) = @_;

  # XMLTV programme desciptor (mandatory parts)
  my %xmltv = (
	       channel => $self->{channel},
	       start   => _epoch_to_xmltv_time($self->{start}),
	       stop    => _epoch_to_xmltv_time($self->{stop}),
	       title   => [[$self->{title}, "fi"]],
	      );
  debug(3, "XMLTV programme '$xmltv{channel}' '$xmltv{start} -> $xmltv{stop}' '$self->{title}'");

  # XMLTV programme descriptor (optional parts)
  if (exists $self->{description}) {
    $xmltv{desc} = [[$self->{description}, "fi"]];
    debug(4, $self->{description});
  }

  $writer->write_programme(\%xmltv);
  $progressbar->update() if $progressbar;
}

# class methods
# Fix overlapping programmes
sub fixOverlaps {
  my($class, $list) = @_;

  # No need to cleanup empty/one-entry lists
  return unless defined($list) && (@{ $list } >= 2);

  my $current = $list->[0];
  foreach my $next (@{ $list }[1..$#{ $list }]) {

    # Does next programme start before current one ends?
    if ($current->{stop} > $next->{start}) {
      debug(3, "Fixing overlapping programme '$current->{title}' $current->{stop} -> $next->{start}.");
      $current->{stop} = $next->{start};
    }

    # Next programme
    $current = $next;
  }
}

# That's all folks
1;
