package Hier::Color;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&color &nl);
}

use Hier::Option;

my $Type = 0;

my %Pri_terminal = (
	"NEXT"	=> 1,
	"DONE"	=> 9,
);

my %Fg_terminal = (
	STRIKE =>	"9",

	BLACK =>	"0;30",
	RED =>		"0;31",
	GREEN =>	"0;32",
	BROWN =>	"0;33",		# dark yellow
	NAVY =>		"0;34",		# dark blue
	PURPLE =>	"0;35",	
	CYAN =>		"0;36",
	GREY =>		"0;37",
	GRAY =>		"0;37",
#light
	SILVER =>	"1;30",		# light black
	PINK =>		"1;31",		# light red
	LIME =>		"1;32",		# light green
	YELLOW =>	"1;33",		# light brown
	BLUE =>		"1;34",		
	MAGENTA =>	"1;35",		# light purple
	AQUA =>		"1;36",		# light cyan
	WHITE =>	"1;37",		# light grey :-)
	NONE =>		"0",
);

my %Bg_terminal = (
	BLACK =>	"40", BK =>		"40",
	RED =>		"41",
	GREEN =>	"42",
	BROWN =>	"43",		# dark yellow
	NAVY =>		"44",		# dark blue
	PURPLE =>	"45",	
	CYAN =>		"46",
	GRAY =>		"47", GREY =>		"47",
#light
	SILVER =>	"40",		# light black
	PINK =>		"41",		# light red
	LIME =>		"42",		# light green
	YELLOW =>	"43",		# light brown
	BLUE =>		"44",		
	MAGENTA =>	"45",		# light purple
	AQUA =>		"46",		# light cyan
	WHITE =>	"47",		# light grey :-)

	WHITE =>	"49",
	NONE =>		"0",
);

sub color {
	my($ref, $fg, $bg) = @_;

	if ($Type == 0) {
		guess_type();
	}

	if ($Type == 1) {
		return;
	}

	if ($Type == 2) {
		color_terminal($ref, $fg, $bg);
		return;
	}

	if ($Type == 3) {
		color_html($ref, $fg, $bg);
	}
}


sub guess_type {
	if (option('Color', 'none') eq 'none') {
		$Type = 1;
		return;
	}

	if (defined $ENV{'LINES'}) {
		$Type = 2 if -t STDOUT;
		return;
	}
	if (defined $ENV{'COLORTERM'}) {
		$Type = 2 if -t STDOUT;
		return;
	}

	if (defined $ENV{'HTTP_ACCEPT'}) {
		$Type = 3;
		return;
	}
	# guess failed, no color
	$Type = 1;
}

sub color_terminal {
	my($ref, $fg, $bg) = @_;

	$fg ||= pick_color_fg($ref);
	$bg ||= pick_color_bg($ref);

	$fg = uc($fg);
	$bg = uc($bg);

	my($cv) = $Fg_terminal{$fg};
	my($bv) = $Bg_terminal{$bg};

#print "$fg=>cv:$cv, $bg=>bv:$bv\n";

	print "\e[". $cv . "m" if defined $cv;
	print "\e[". $bv . "m" if defined $bv;

}

sub color_html {
	my($ref, $color) = @_;

	$color ||= pick_color($ref);
}

sub pick_color_pri {
	my($ref) = @_;

	return '' unless defined $ref;
	# pick context
	# pick pri
	# pick category


#	return 'BOLD' if $ref->is_nextaction();

	return '';
}
sub pick_color_fg {
	my($ref) = @_;

	return '' unless defined $ref;
	# pick context
	# pick pri
	# pick category

	return 'RED' if $ref->is_nextaction();
	return 'GREY' if $ref->is_someday();
	return 'STRIKE' if $ref->get_completed();

	my($pri) = $ref->get_priority();
	return 'PINK' if $pri >= 3;

	return '';
}

sub pick_color_bg {
	my($ref) = @_;

	return '' unless defined $ref;
	# pick context
	# pick pri
	# pick category

	my($context) = uc($ref->get_context());

	return 'YELLOW' if $context eq 'CC';
	return 'RED'    if $context eq 'HOME';
	return 'BLUE'   if $context eq 'OFFICE';
	return 'CYAN'   if $context eq 'COMPUTER';
	return 'PURPLE' if $context eq 'MAUREEN';
	return 'GREY'   if $context eq 'HOME';

	#return 'YELLOW' if $ref->get_type eq 'm';	# Value
	#return 'YELLOW' if $ref->get_type eq 'v';	# Vision
	#return 'BLUE' if $ref->get_type eq 'o';	# Vision

	return '';
}

sub nl {
	color(undef, 'NONE', 'NONE');
	print "\n";
}
