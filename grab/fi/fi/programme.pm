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

# Configuration data
my %series_description;
my %series_title;

sub dump {
  my($self, $writer, $progressbar) = @_;
  my $title       = $self->{title};
  my $description = $self->{description};
  my $subtitle;

  #
  # Programme post-processing
  #
  # Check 1: title contains episode name
  #
  # If title contains a colon (:), check to see if the string on the left-hand
  # side of the colon has been defined as a series in the configuration file.
  # If it has, assume that the string on the left-hand side of the colon is
  # the name of the series and the string on the right-hand side is the name
  # of the episode.
  #
  # Example:
  #
  #   config: series title Prisma
  #   title:  Prisma: Totuus tappajadinosauruksista
  #
  # This will generate a program with
  #
  #   title:     Prisma
  #   sub-title: Totuus tappajadinosauruksista
  #
  my($left, $right);
  if ((($left, $right) = ($title =~ /([^:]+):\s*(.*)/)) &&
      (exists $series_title{$left})) {
    debug(3, "XMLTV series title '$left' episode '$right'");
    ($title, $subtitle) = ($left, $right);
  }
  #
  # Check 2: description contains episode name
  #
  # Check if the program has a description. If so, also check if the title
  # of the program has been defined as a series in the configuration. If it
  # has, assume that the first sentence (i.e. the text before the first
  # period) marks the name of the episode.
  #
  # Example:
  #
  #   config:      series title Batman
  #   description: Pingviinin paluu. Amerikkalainen animaatiosarja....
  #
  # This will generate a program with
  #
  #   title:       Batman
  #   sub-title:   Pingviinin paluu.
  #   description: Amerikkalainen animaatiosarja....
  #
  elsif ((defined $description)               &&
	 (exists $series_description{$title}) &&
         (($left, $right) = ($description =~ /^\s*([^.]+)\.\s*(.*)/))) {
    debug(3, "XMLTV series title '$title' episode '$left'");
    ($subtitle, $description) = ($left, $right);
  }

  # XMLTV programme desciptor (mandatory parts)
  my %xmltv = (
	       channel => $self->{channel},
	       start   => _epoch_to_xmltv_time($self->{start}),
	       stop    => _epoch_to_xmltv_time($self->{stop}),
	       title   => [[$title, "fi"]],
	      );
  debug(3, "XMLTV programme '$xmltv{channel}' '$xmltv{start} -> $xmltv{stop}' '$self->{title}'");

  # XMLTV programme descriptor (optional parts)
  if (defined($subtitle)) {
    $xmltv{'sub-title'} = [[$subtitle, "fi"]];
    debug(3, "XMLTV programme episode: $subtitle");
  }
  if (defined($description) && length($description)) {
    $xmltv{desc} = [[$description, "fi"]];
    debug(4, $description);
  }

  $writer->write_programme(\%xmltv);
  $progressbar->update() if $progressbar;
}

# class methods
# Parse config line
sub parseConfigLine {
  my($class, $line) = @_;

  # Extract words
  my($series, $keyword, $param) = split(' ', $line, 3);
  return unless $series eq "series";

  if ($keyword eq "description") {
    $series_description{$param}++;
  } elsif ($keyword eq "title") {
    $series_title{$param}++;
  } else {
    # Unknown series configuration
    return;
  }

  return(1);
}

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
