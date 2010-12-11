#!/usr/bin/perl -w
# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# Setup
#
###############################################################################
use 5.008; # we process Unicode texts
use strict;
use warnings;

# Perl core modules
use Getopt::Long;
use Pod::Usage;

# Load internal modules
use File::Basename;
use FindBin qw($Bin $Script);
my @sources;
BEGIN {
  my $basename = basename($Script, ".pl");
  foreach my $source (<$Bin/$basename/source/*.pm>) {
    require "$source";
  }
  @sources = map { s/::$//; $_ }
    map { $basename . "::source::" . $_ }
    sort
    keys %{ $::{$basename . "::"}->{'source::'} };
  die "$0: couldn't find any source modules?" unless @sources;
}

# XMLTV modules
use XMLTV::Version '$Id: tv_grab_fi,v 1.999 yyy/mm/dd hh:mm:ss xxx Exp $ ';
use XMLTV::Capabilities qw(baseline manualconfig cache);
use XMLTV::Description 'Finland (' .
  join(', ', map { $_->description() } @sources ) .
  ')';

###############################################################################
#
# Main program
#
###############################################################################
# Command line option default values
my %Option = (
	     );

# Process command line options
if (GetOptions(\%Option,
	       "configure",
	       "help|h|?",
	       "list-channels")) {

  pod2usage(-exitstatus => 0,
	    -verbose => 2)
    if $Option{help};

  if ($Option{configure}) {
    # Configure mode
    print STDERR "NOT IMPPLEMENTED YET...\n";

  } elsif ($Option{'list-channels'}) {
    # List channels mode
    print STDERR "NOT IMPPLEMENTED YET...\n";

  } else {
    # Grab mode (default)
    print STDERR "NOT IMPPLEMENTED YET...\n";
  }
} else {
  pod2usage(2);
}

# That's all folks
exit 0;

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
           [--config-file E<lt>FILEE<gt>]
           [--gui [E<lt>OPTIONE<gt>]]

tv_grab_fi  --description

tv_grab_fi  --help|-h|-?

tv_grab_fi  --list-channels

tv_grab_fi  --version

=head1 DESCRIPTION

Grab TV listings for several channels available in Finland. The data comes
from various sources, e.g. www.telkku.com. The grabber relies on parsing HTML,
so it might stop working when the web page layout is changed..

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

=item B<--cache F<FILE>>

File name to cache the fetched HTML data in. This speeds up subsequent runs
using the same data.

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

=item B<--quiet>

Suppress any progress messages to the standard output.

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
