package GTD::Report::projects;

=head1 NAME

=head1 USAGE

=head1 REQUIRED ARGUMENTS

=head1 OPTION

=head1 DESCRIPTION

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE and COPYRIGHT

(C) Drew Sullivan 2015 -- LGPL 3.0 or latter

=head1 HISTORY

=cut

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_projects);
}

use GTD::Util;
use GTD::Meta;
use GTD::Sort;
use GTD::Option;
use GTD::Format;

my %Meta_key;

sub Report_projects {	#-- List projects -- live, plan or someday
	meta_filter('+p:next', '^goaltask', 'simple');

	report_header("Projects",  meta_desc(@_));

	my($work_load) = 0;
	my($proj_cnt) = 0;
	my($ref, $proj, %wanted, %counted, %actions);

	my(@projects) = meta_matching_type('p');

	# note all parents so we don't include them latter.
	my(%parent);
	for my $ref (@projects) {
		for my $pref ($ref->get_parents()) {
			$parent{$pref->get_tid()}++;
		}
	}
	# find all next and remember there projects
#	for my $ref (@projects) {
#
#		my $pid = $ref->get_tid();
#		$wanted{$pid} = $ref;
#		$counted{$pid} = 0;
#		$actions{$pid} = 0;
#
#		for my $child ($ref->get_children()) {
#			$counted{$pid}++ unless $child->filtered();
#			$actions{$pid}++;
#
#			$work_load++ unless $child->filtered();
#		}
#	}

	for my $ref (@projects) {
		next if $parent{$ref->get_parent()};

		my($work, $counts) = summary_children($ref);
		$work_load += $work;
#		display_rgpa($ref, $counts);
		display_task($ref, $counts);

		++$proj_cnt;
	}
	print "***** Work Load: $proj_cnt Projects, $work_load action items\n";
}

1;  # don't forget to return a true value from the file
