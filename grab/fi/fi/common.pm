# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: common code
#
###############################################################################
#
# Setup
#
# INSERT FROM HERE ############################################################
package fi::common;
use base qw(Exporter);

our @EXPORT      = qw(message debug);
our @EXPORT_OK   = qw(setQuiet setDebug);
our %EXPORT_TAGS = (
		    main => [qw(message debug setQuiet setDebug)],
		   );

# Normal message, disabled with --quiet
{
  my $quiet = 0;
  sub message(@)  { print STDERR "@_\n" unless $quiet }
  sub setQuiet($) { ($quiet) = @_ }
}

# Debug message, enabled with --debug
{
  my $debug = 0;
  sub debug($@) {
    my $level = shift;
    print STDERR "@_\n" unless $debug < $level;
  }
  sub setDebug($) {
    ($debug) = @_;
    debug(1, "Debug level set to $debug.");
  }
}

# That's all folks
1;
