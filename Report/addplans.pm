package Hier::Report::addplans;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_addplans);
}

use Hier::util;
use Hier::Meta;
use Hier::Sort;
use Hier::Filter;
use Hier::Format;
use Hier::Option;

my $Debug;

my @List = ();

my($Work_load) = 0;
my($Proj_cnt) = 0;

my $Limit;
my %Seen;

sub Report_addplans {	#-- add plan action items to unplaned projects
	meta_filter('+live', '^goaltask', 'simple');

	$Debug = option('Debug', 0);

	@List = meta_pick(@_);
	if (@List == 0) {
		@List = meta_pick('Project');
		$Limit = option('Limit', 10);
	} else {
		$Limit = option('Limit', scalar(@List));
	}
	report_header('Projects needing planing');

	# find all next and remember there focus
	while (@List) {
		my($ref) = shift @List;

		my($tid) = $ref->get_tid();
		next if $Seen{$tid}++;

		my($reason) = check_task($ref);
		next unless $reason;

		display_rgpa($ref, "(PLAN: $reason)");
		last if --$Limit < 0;
	}
}

sub check_task {
	my($ref) = @_;

	my($type) = $ref->get_type();

	return unless $ref->is_hier();

	my($pid) = $ref->get_tid();
	my($title) = $ref->get_title();
	my($desc) = $ref->get_description();
	my($result) = $ref->get_note();

   if ($type ne 'p') {
	return "Need wiki ref" unless $title =~ /\[\[.*\]\]/;
   }
	return "Need description" unless $desc;
	return "Need result" unless $result;

	my(@children) = $ref->get_children();
	return "Need children"  unless @children;

	my($work, $children) = count_children($ref);
	print "$pid: $children\n" if $Debug;

	return "Needs next action" unless $work;

	push(@List, @children);

	return;
}

1;  # don't forget to return a true value from the file
