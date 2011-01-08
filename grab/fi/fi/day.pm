# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: day class
#
###############################################################################
#
# Setup
#
# VERSION: $Id: day.pm,v 1.999 yyyy/mm/dd hh:mm:ss xxx Exp $
#
# INSERT FROM HERE ############################################################
package fi::day;
use strict;
use warnings;
use Carp;
use Date::Manip qw(DateCalc ParseDate UnixDate);

# Overload stringify operation
use overload '""' => "ymd";

# Constructor (private)
sub _new {
  my($class, $day, $month, $year) = @_;

  my $self = {
	      day   => $day,
	      month => $month,
	      year  => $year,
	      ymd   => sprintf("%04d%02d%02d", $year, $month, $day),
	     };

  return(bless($self, $class));
}

# instance methods
sub day   { $_[0]->{day}   };
sub month { $_[0]->{month} };
sub year  { $_[0]->{year}  };
sub ymd   { $_[0]->{ymd}   };

# class methods
sub generate {
  my($class, $offset, $days) = @_;

  # Start one day before offset
  my $date = DateCalc(ParseDate("today"), ($offset - 1) . " days")
    or croak("can't calculate start day");

  # End one day after offset + days
  my @dates;
  for (0..$days + 1) {
    my($year, $month, $day) = split(':', UnixDate($date, "%Y:%m:%d"));
    push(@dates, $class->_new(int($day), int($month), int($year)));
    $date  = DateCalc($date, "+1 day")
      or croak("can't calculate next day");
  }
  return(\@dates);
}

# That's all folks
1;
