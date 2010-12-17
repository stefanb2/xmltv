#!/usr/bin/perl -w
# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# Setup
#
###############################################################################
use 5.008; # we process Unicode texts
use strict;
use warnings;

###############################################################################
# INSERT: SOURCES
###############################################################################
package main;

# Perl core modules
use Getopt::Long;
use Pod::Usage;

# CUT CODE START
###############################################################################
# Load internal modules
use FindBin qw($Bin);
BEGIN {
  foreach my $source (<$Bin/fi/*.pm>, <$Bin/fi/source/*.pm>) {
    require "$source";
  }
}
###############################################################################
# CUT CODE END

# Generate source module list
my @sources;
BEGIN {
  @sources = map { s/::$//; $_ }
    map { "fi::source::" . $_ }
    sort
    keys %{ $::{'fi::'}->{'source::'} };
  die "$0: couldn't find any source modules?" unless @sources;
}

# Import from internal modules
fi::common->import(':main');

# Basic XMLTV modules
use XMLTV::Version '$Id: tv_grab_fi,v 1.999 yyy/mm/dd hh:mm:ss xxx Exp $ ';
use XMLTV::Capabilities qw(baseline manualconfig cache);
use XMLTV::Description 'Finland (' .
  join(', ', map { $_->description() } @sources ) .
  ')';

# NOTE: We will only reach the rest of the code only when the script is called
#       without --version, --capabilities or --description
# Reminder of XMLTV modules
use XMLTV::Get_nice;
use XMLTV::Memoize;

###############################################################################
#
# Main program
#
###############################################################################
# Forward declarations
sub doListChannels();
sub doGrab();

# Command line option default values
my %Option = (
	      days   => 14,
	      quiet  =>  0,
	      debug  =>  0,
	      offset =>  0,
	     );

# Enable caching. This will remove "--cache [file]" from @ARGV
XMLTV::Memoize::check_argv('XMLTV::Get_nice::get_nice_aux');

# Process command line options
if (GetOptions(\%Option,
	       "configure",
	       "config-file=s",
	       "days=i",
	       "debug|d+",
	       "help|h|?",
	       "list-channels",
	       "offset=i",
	       "output=s",
	       "quiet")) {

  pod2usage(-exitstatus => 0,
	    -verbose => 2)
    if $Option{help};

  setDebug($Option{debug});
  setQuiet($Option{quiet});

  if ($Option{configure}) {
    # Configure mode
    print STDERR "NOT IMPPLEMENTED YET...\n";

  } elsif ($Option{'list-channels'}) {
    # List channels mode
    doListChannels();

  } else {
    # Grab mode (default)
    doGrab();
  }
} else {
  pod2usage(2);
}

# That's all folks
exit 0;

###############################################################################
#
# Utility functions for the different modes
#
###############################################################################
{
  my $ofh;

  sub _createXMLTVWriter() {

    # Output file handling
    $ofh = \*STDOUT;
    if (defined $Option{output}) {
      open($ofh, ">", $Option{output})
	or die "$0: cannot open file '$Option{output}' for writing: $!";
    }

    # Create XMLTV writer for UTF-8 encoded text
    binmode($ofh, ":utf8");
    my $writer = XMLTV::Writer->new(
				    encoding => 'UTF-8',
				    OUTPUT   => \*STDOUT,
				   );

    #### HACK CODE ####
    $writer->start({
		    "generator-info-name" => "XMLTV",
		    "generator-info-url"  => "http://xmltv.org/",
		    "source-info-url"     => "multiple", # TBA
		    "source-data-url"     => "multiple", # TBA
		   });
    #### HACK CODE ####

    return($writer);
  }

  sub _closeXMLTVWriter($) {
    my($writer) = @_;
    $writer->end();

    # close output file
    if ($Option{output}) {
      close($ofh) or die "$0: write error on file '$Option{output}': $!";
    }
  }
}

###############################################################################
#
# List Channels Mode
#
###############################################################################
sub doListChannels() {
  # Create XMLTV writer
  my $writer = _createXMLTVWriter();

  # Get channels from all sources
  foreach my $source (@sources) {
    debug(1, "requesting channel list from source '" . $source->description ."'");
    if (my $list = $source->channels()) {
      foreach (my($id, $name) = each %{ $list }) {
	$writer->write_channel($id, $name);
      }
    }
  }

  # Done writing
  _closeXMLTVWriter($writer);
}

###############################################################################
#
# Grab Mode
#
###############################################################################
sub doGrab() {
  # Sanity check
  die "$0: --offset must be a non-negative integer"
    unless $Option{offset} >= 0;
  die "$0: --days must be an integer larger than 0"
    unless $Option{days} > 0;

  # Get configuation
  my %channels;
  {
    # Get configuration file name
    require XMLTV::Config_file;
    my $file = XMLTV::Config_file::filename($Option{'config-file'},
					    "tv_grab_fi",
					    $Option{quiet});

    # Open configuration file. Assume UTF-8 encoding
    open(my $fh, "<:utf8", $file)
      or die "$0: can't open configuration file '$file': $!";

    # Process configuration information
    while (<$fh>) {

      # Comment removal, white space trimming and compressing
      s/\#.*//;
      s/^\s+//;
      s/\s+$//;
      next unless length;	# skip empty lines
      s/\s+/ /;

      # Channel definition
      if (my($id, $name) = /^channel (\S+) (.+)/) {
	debug(1, "duplicate channel definion in line $.:$id ($name)")
	  if exists $channels{$id};
	$channels{$id} = $name;

	# For now ignore the rest...
      } else {
	# TBA...
      }
    }

    close($fh);
  }

  # Generate list of days
  my $dates = fi::day->generate($Option{offset}, $Option{days});

  # Create XMLTV writer
  my $writer = _createXMLTVWriter();

  # For each channel and each day
  my %seen;
  my @programmes;
  foreach my $id (sort keys %channels) {
    debug(1, "XMLTV channel ID: $id");
    for (my $i = 1; $i < $#{ $dates }; $i++) {
      debug(1, "Fetching day $dates->[$i]");
      foreach my $source (@sources) {
	if (my $programmes = $source->grab($id,
					   @{ $dates }[$i - 1..$i + 1])) {
	  # Add channel ID & name (once)
	  $writer->write_channel({
				  id             => $id,
				  'display-name' => [[$channels{$id}, "fi"]],
				 })
	    unless $seen{$id}++;

	  # Add programmes to list
	  push(@programmes, @{ $programmes });
	}
      }
    }
  }

  # Dump programs
  $_->dump($writer) foreach (@programmes);

  # Done writing
  _closeXMLTVWriter($writer);
}

###############################################################################
#
# Man page
#
###############################################################################
__END__
=pod

=head1 NAME

tv_grab_fi - Grab TV listings for Finland

=head1 SYNOPSIS

tv_grab_fi [--cache E<lt>FILEE<gt>]
           [--config-file E<lt>FILEE<gt>]
           [--days E<lt>NE<gt>]
           [--offset E<lt>NE<gt>]
           [--output E<lt>FILEE<gt>]
           [--quiet]

tv_grab_fi  --capabilities

tv_grab_fi  --configure
           [--cache E<lt>FILEE<gt>]
           [--config-file E<lt>FILEE<gt>]
           [--gui [E<lt>OPTIONE<gt>]]
           [--quiet]

tv_grab_fi  --description

tv_grab_fi  --help|-h|-?

tv_grab_fi  --list-channels
           [--cache E<lt>FILEE<gt>]
           [--quiet]

tv_grab_fi  --version

=head1 DESCRIPTION

Grab TV listings for several channels available in Finland. The data comes
from various sources, e.g. www.telkku.com. The grabber relies on parsing HTML,
so it might stop working when the web page layout is changed.

You need to run C<tv_grab_fi --configure> first to create the channel
configuration for your setup. Subsequently runs of C<tv_grab_fi> will grab
the latest data, process them and produce XML data on the standard output.

=head1 COMMANDS

=over 8

=item B<NONE>

Grab mode.

=item B<--capabilities>

Show the capabilities this grabber supports. See also
L<http://wiki.xmltv.org/index.php/XmltvCapabilities>.

=item B<--configure>

Generate the configuration file by asking the users which channels to grab.

=item B<--description>

Print the description for this grabber.

=item B<--help|-h|-?>

Show this help page.

=item B<--list-channels>

Fetch all available channels from the various sources and write them to the
standard output.

=item B<--version>

Show the version of this grabber.

=back

=head1 GENERIC OPTIONS

=over 8

=item B<--cache F<FILE>>

File name to cache the fetched HTML data in. This speeds up subsequent runs
using the same data.

=item B<--quiet>

Suppress any progress messages to the standard output.

=back

=head1 CONFIGURE MODE OPTIONS

=over 8

=item B<--config-file F<FILE>>

File name to write the configuration to.

Default is F<$HOME/.xmltv/tv_grab_fi.conf>.

=item B<--gui [OPTION]>

Enable the graphical user interface. If you don't specify B<OPTION> then
XMLTV will automatically choose the best available GUI. Allowed values are:

=over 4

=item B<Term>

Terminal output with a progress bar

=item B<TermNoProgressBar>

Terminal output without progress bar

=item B<Tk>

Tk-based GUI

=back

=back

=head1 GRAB MODE OPTIONS

=over 8

=item B<--config-file F<FILE>>

File name to read the configuration from.

Default is F<$HOME/.xmltv/tv_grab_fi.conf>.

=item B<--days C<N>>

Grab C<N> days of TV data.

Default is 14 days.

=item B<--offset C<N>>

Grab TV data starting at C<N> days in the future.

Default is 0, i.e. today.

=item B<--output F<FILE>>

Write the XML data to F<FILE> instead of the standard output.

=back

=head1 SEE ALSO

L<xmltv>.

=head1 AUTHOR

=head2 Current

=over

=item Stefan Becker C<stefan dot becker at nokia dot com>

=item Ville Ahonen C<ville dot ahonen at iki dot fi>

=back

=head2 Retired

=over

=item Matti Airas

=back

=head1 BUGS

The channels are identified by channel number rather than the RFC2838 form
recommended by the XMLTV DTD.

=cut
