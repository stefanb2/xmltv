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
use Carp;
use POSIX qw(strftime);

# Import from internal modules
fi::common->import();

# Constructor
sub new {
  my($class, $channel, $title, $start, $stop) = @_;
  croak "${class}::new called without valid title, start or stop"
    unless defined($channel) && defined($title) &&
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
  $self->{description} = $description;
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
	       title   => $self->{title},
	      );
  debug(3, "XMLTV programme '$xmltv{start}':'$xmltv{stop}' '$xmltv{title}'");

  # XMLTV programme descriptor (optional parts)
  if (exists $self->{description}) {
    $xmltv{desc} = $self->{description};
    debug(4, "XMLTV programme '$xmltv{description}'");
  }

  $writer->write_programme(\%xmltv);
  $progressbar->update() if $progressbar;
}

# That's all folks
1;
