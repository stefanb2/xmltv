# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: generate programme list using start times only
#
###############################################################################
#
# Setup
#
# INSERT FROM HERE ############################################################
package fi::programmeStartOnly;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT = qw(startProgrammeList appendProgramme convertProgrammeList);

# Import from internal modules
fi::common->import();

sub startProgrammeList() { return([]) }

sub appendProgramme($$$$$$) {
  my($programmes, $hour, $minute, $title, $description) = @_;

  push(@{ $programmes }, {
			  description => $description,
			  hour        => $hour,
			  minute      => $minute,
			  # minutes since midnight
			  start       => $hour * 60 + $minute,
			  title       => $title,
			 });
}

sub convertProgrammeList($$$$$$) {
  my($programmes, $id, $language, $yesterday, $today, $tomorrow) = @_;

  # No data found -> return empty list
  return unless @{ $programmes };

  # Check for day crossing between first and second entry
  my @dates = ($today, $tomorrow);
  unshift(@dates, $yesterday)
    if ((@{ $programmes } > 1) &&
	($programmes->[0]->{start} > $programmes->[1]->{start}));

  my @objects;
  my $date          = shift(@dates);
  my $current       = shift(@{ $programmes });
  my $current_start = $current->{start};
  my $current_epoch = timeToEpoch($date, $current->{hour}, $current->{minute});
  foreach my $next (@{ $programmes }) {

    # Start of next program might be on the next day
    my $next_start = $next->{start};
    $date          = shift(@dates)
      if $current_start > $next_start;
    my $next_epoch = timeToEpoch($date, $next->{hour}, $next->{minute});

    # Create program object
    debug(3, "Programme $id ($current_epoch -> $next_epoch) $current->{title}");
    my $object = fi::programme->new($id, $language, $current->{title},
				    $current_epoch, $next_epoch);
    $object->description($current->{description});
    push(@objects, $object);

    # Move to next program
    $current       = $next;
    $current_start = $next_start;
    $current_epoch = $next_epoch;
  }

  return(\@objects);
}

# That's all folks
1;
