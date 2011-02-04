# -*- mode: perl; coding: utf-8 -*- ###########################################
#
# tv_grab_fi: source specific grabber code for http://www.telvis.fi
#
###############################################################################
#
# Setup
#
# VERSION: $Id: telvis.pm,v 1.999 yyyy/mm/dd hh:mm:ss xxx Exp $
#
# INSERT FROM HERE ############################################################
package fi::source::telvis;
use strict;
use warnings;

# Import from internal modules
fi::common->import();
fi::programmeStartOnly->import();

# Description
sub description { 'telvis.fi' }

# Grab channel list
sub channels {
  my %channels;

  # Fetch & parse HTML
  my $root = fetchTree("http://www.telvis.fi/tvohjelmat/?vw=channel");
  if ($root) {

    #
    # Channel list can be found in multiple <div> nodes
    #
    # <div class="progs" style="text-align:left;">
    #  <a href="/tvohjelmat/?vw=channel&ch=tv1&sh=new&dy=03.02.2011">YLE TV1</a>
    #  <a href="/tvohjelmat/?vw=channel&ch=tv2&sh=new&dy=03.02.2011">YLE TV2</a>
    #  ...
    # </div>
    #
    if (my @containers = $root->look_down("class" => "progs")) {
      foreach my $container (@containers) {
	if (my @refs = $container->find("a")) {
	  debug(2, "Source telvis.fi found " . scalar(@refs) . " channels");
	  foreach my $ref (@refs) {
	    my $href = $ref->attr("href");
	    my $name = $ref->as_text();

	    if (defined($href) && length($name) &&
		(my($id) = ($href =~ m,vw=channel&ch=([^&]+)&,))) {
	      debug(3, "channel '$name' ($id)");
	      $channels{"${id}.telvis.fi"} = "fi $name";
	    }
	  }
	}
      }
    }

    # Done with the HTML tree
    $root->delete();

  } else {
    return;
  }

  debug(2, "Source telvis.fi parsed " . scalar(keys %channels) . " channels");
  return(\%channels);
}

# Grab one day
sub grab {
  my($self, $id, $yesterday, $today, $tomorrow) = @_;

  # Get channel number from XMLTV id
  return unless my($channel) = ($id =~ /^([^.]+)\.telvis\.fi$/);

  # Fetch & parse HTML
  my $root = fetchTree("http://www.telvis.fi/lite/?vw=channel&ch=${channel}&dy=" . $today->dmy(),
		       "iso-8859-1");
  if ($root) {
    my %channels;

    #
    # Each programme can be found in a separate <tr> node under a <div> node
    #
    # <div class="tm">
    #  <table>
    #   ...
    #   <tr>
    #    <td valign="top"><strong>13:50</strong></td>
    #    <td><strong>Serranon perhe</strong>&nbsp;
    #     Suuret sanat suuta halkovat. Diego kertoo perheelleen suhteestaan Celiaan. Reaktiot pistävät miehelle jauhot suuhun. Ana pyytää Fitiltä palvelusta, josta tämä on otettu. Santi hoitaa Lourditasin asioita omin päin.
    #    </td>
    #   </tr>
    #   <tr class="zeb">
    #    <td valign="top"><strong>15:15</strong></td>
    #    <td><strong>Gilmoren tytöt</strong>&nbsp;
    #     Välirikko. Emily yrittää tuoda Christopherin takaisin perheensä piiriin, mutta Rory on saanut aina poissaolevasta isästä tarpeekseen. Lorelaita piirittää jälleen uusi ihailija.
    #    </td>
    #   </tr>
    #   ...
    #  </table>
    # </div>
    #
    my $opaque = startProgrammeList();
    if (my $container = $root->look_down("class" => "tm")) {
      if (my @rows = $container->find("tr")) {
	foreach my $row (@rows) {
	  my @columns = $row->find("td");
	  if (@columns == 2) {
	    my $start = $columns[0]->find("strong");
	    my $title = $columns[1]->find("strong");
	    if ($start && $title) {
	      $start = $start->as_text();
	      $title = $title->as_text();
	      if (my($hour, $minute) = ($start =~ /^(\d{2}):(\d{2})/)) {
		my $desc  = $columns[1]->as_text(); # includes $title
		$desc =~ s/^$title\s+//;
		debug(3, "List entry $channel ($hour:$minute) $title");
		debug(4, $desc);

		# Only record entry if title isn't empty
		appendProgramme($opaque, $hour, $minute, $title, undef, $desc)
		  if length($title) > 0;
	      }
	    }
	  }
	}
      }
    }

    # Done with the HTML tree
    $root->delete();

    # Convert list to program objects
    return(convertProgrammeList($opaque, $id, "fi",
				$yesterday, $today, $tomorrow));
  }

  return;
}

# That's all folks
1;
