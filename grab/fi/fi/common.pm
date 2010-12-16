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
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT      = qw(message debug fetchRaw fetchTree);
our @EXPORT_OK   = qw(setQuiet setDebug);
our %EXPORT_TAGS = (
		    main => [qw(message debug setQuiet setDebug)],
		   );

# Perl core modules
use Carp;
use Encode qw(decode_utf8);

# Other modules
use HTML::TreeBuilder;
use XMLTV::Get_nice;

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
    if (($debug) = @_) {
      # Debug messages may contain Unicode
      binmode(STDERR, ":utf8");
      debug(1, "Debug level set to $debug.");
    }
  }
}

# Fetch URL as UTF8 encoded string
sub fetchRaw($) {
  my($url) = @_;
  debug(2, "Fetching URL '$url'");
  my $content = eval { decode_utf8(get_nice($url)) };
  croak "fetchRaw(): $@" if $@;
  debug(5, $content);
  return($content);
}

# Fetch URL as parsed HTML::TreeBuilder
sub fetchTree($) {
  my($url) = @_;
  my $content = fetchRaw($url);
  my $tree = HTML::TreeBuilder->new();
  local $SIG{__WARN__} = sub { carp("fetchTree(): $_[0]") };
  $tree->parse($content) or croak("fetchTree() parse failure for '$url'");
  $tree->eof;
  return($tree);
}

# That's all folks
1;
