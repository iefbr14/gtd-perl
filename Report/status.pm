package Hier::Report::status;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &Report_status );
}

my %Types = (
        'Value'         => 'm',
        'Vision'        => 'v',

        'Role'          => 'o',
        'Goal'          => 'g',

        'Project'       => 'p',

        'Action'        => 'a',
        'Inbox'         => 'i',
        'Waiting'       => 'w',

        'Reference'     => 'r',

        'List'          => 'L',
        'Checklist'     => 'C',
        'Item'          => 'T',
);


use Hier::util;
use Hier::Filter;
use Hier::Meta;
use Hier::Option;
use Hier::Filter;

sub Report_status {	#-- report status of projects/actions
	# counts use it and it give a context
	meta_filter('+live', '^tid', 'none');	

	my $desc = meta_desc(@ARGV);
	
	my $hier = count_hier();
	my $proj = count_proj();
	my $task = count_task();
	my $next = count_next();

#	print "Options:\n";
#	for my $option (qw(pri debug db title report)) {
#		printf "%10s %s\n", $option, get_info($option);
#	}
#	print "\n";

	print "For: $desc " if $desc;
	my($total) = $task + $next;
	print "hier: $hier, projects: $proj, next/actions: $next/$task = $total\n";

	my($t_p) = '-';
	my($t_n) = '-';
	my($t_a) = '-';
	my($time) = '?';
	print "time: $time, projects: $t_p, next/actions: $t_n/$t_a\n";
}

sub count_hier {
	my($count) = 0;

	# find all hier records
	foreach my $ref (meta_all()) {
		next unless $ref->is_hier();
		next if $ref->filtered();

		++$count;
	}
	return $count;
}

sub count_proj {
	my($count) = 0;

	# find all projects
	foreach my $ref (meta_matching_type('p')) {
###FILTER	next if $ref->filtered();

		++$count;
	}
	return $count;
}

sub count_liveproj {
	my($count) = 0;

	# find all projects
	foreach my $ref (meta_matching_type('p')) {
###FILTER	next if $ref->filtered();

		next unless project_live($ref);

		++$count;
	}
	return $count;
}

sub count_task {
	my($count) = 0;
	my($time) = 0;

	# find all records.
	foreach my $ref (meta_selected()) {
		next unless $ref->is_task();

		next if $ref->filtered();

		next unless project_live($ref);

		++$count;
	}
	return $count;
}

sub count_next {
	my($count) = 0;
	my($time) = 0;

	# find all records.
	foreach my $ref (meta_selected()) {
		next unless $ref->is_task();

		next if $ref->filtered();

		next unless project_live($ref);

		next unless $ref->is_nextaction();

		++$count;
	}
	return $count;
}

sub count_tasklive {
	my($count) = 0;
	my($time) = 0;

	# find all records.
	foreach my $ref (meta_selected()) {

		next unless $ref->is_task();

		next if $ref->filtered();
		next unless project_live($ref);

		++$count;
	}
	return $count;
}

sub project_live {
	my($ref) = @_;

	return $ref->get_live() if defined $ref;

	my($type) = $ref->get_type();

	if ($ref->is_task()) {
		$ref->get_live() = ! task_filtered($ref);
		return $ref->get_live();
	}

	if ($ref->is_hier()) {
		foreach my $pref ($ref->get_parents()) {
			$ref->get_live() |= project_live($pref);
		}
		foreach my $cref ($ref->get_children()) {
			$ref->get_live() |= project_live($cref);
		}
	
		$ref->get_live() = ! task_filtered($ref);
		return $ref->get_live();
	}

	return 0;
}

1;
