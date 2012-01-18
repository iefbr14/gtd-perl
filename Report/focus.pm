package Hier::Report::focus;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_focus);
}

use Hier::Meta;
use Hier::Filter;
use Hier::Sort;
use Hier::Format;
use Hier::Option;

my %Meta_key;

my($Format) = \&focus_summary;

my($Work_load) = 0;
my($Proj_cnt) = 0;

sub Report_focus {	#-- List focus -- live, plan or someday

	my($cnt) = 0;

	meta_filter('+p:next', '^focus', 'simple');

	my($pick) = {
		doit => \&display_mode,
		detail => \&display_mode,
	};

	my(@list) = meta_pick($pick, @_);
	if (@list == 0) {
		@list = meta_pick($pick, 'Vision');
	}

	report_header(join(' ', "Focus", @_));

	# find all next and remember there focus
	for my $r_ref (sort_tasks @list) {
		unless (display_cond($r_ref)) {
			display_task($r_ref, '(PLAN)');
		}
	}
	print "***** Work Load: $Proj_cnt Projects, $Work_load action items\n";
}

sub report_task {
	my($tid) = @_;

	my($ref) = meta_find($tid);

	unless (defined $ref) {
		warn "No such task: $ref\n";
		return;
	}
	display_task($ref);
}

sub display_cond {
	my($p_ref) = @_;

    foreach my $ref (sort_tasks $p_ref->get_children()) {
	next unless $ref->is_nextaction();
	next if $ref->get_completed();
	next if $ref->filtered();

	my($work, $counts);
	if ($p_ref->get_type() eq 'p') {
		($work, $counts) = count_children($p_ref);
		$Work_load += $work;
		++$Proj_cnt;

		if ($ref->get_type() eq 'a') {
				display_hier($p_ref, $counts);
				display_task($ref);
				return 1;
		}
	}

	return 1 if display_cond($ref);
	return 0;
   }
}


1;  # don't forget to return a true value from the file
