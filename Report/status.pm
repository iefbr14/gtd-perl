package Hier::Report::status;

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

my @Class = qw(Done Someday Action Next Future Total);


use Hier::util;
use Hier::Meta;
use Hier::Option;
use Hier::Resource;

my $Hours_task = 0;
my $Hours_next = 0;

sub Report_status {	#-- report status of projects/actions
	# counts use it and it give a context
	meta_filter('+active', '^tid', 'none');	

	my $desc = meta_desc(@_);

	if (lc($desc) eq 'all') {
		report_detail();
		exit 0;
	}
	
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
	print "hier: $hier, projects: $proj, next,actions: $next+$task = $total\n";

	my($t_p) = '-';
	my($t_a) = $Hours_task;
	my($t_n) = $Hours_next;

	my($time) = '?';
	print "time: $time, projects: $t_p, next,actions: $t_n,$t_a\n";
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

		my($resource) = new Hier::Resource($ref);
		$Hours_task += $resource->hours($ref);
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

		my($resource) = new Hier::Resource($ref);
		$Hours_next += $resource->hours($ref);
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

sub calc_type {
	my($ref) = @_;

	return 'h' if $ref->is_hier();
	return 'a' if $ref->is_task();
	return 'l';
}

sub calc_class {
	my($ref) = @_;

	return 'd' if $ref->get_completed();
	return 's' if $ref->is_someday();
	return 'f' if $ref->is_later();

	return 'n' if $ref->is_nextaction();
	return 'a';
}

sub report_detail {
	meta_filter('+all', '^title', 'simple');

	my @Types = qw(Hier Action List Total);
	my @Class = qw(Done Someday Action Next Future Total);

	my(%data);
	my($type, $class);
	for my $ref (meta_all()) {
		$type = calc_type($ref);
		$class = calc_class($ref);

		++$data{$type}{$class};

		# totals;
		++$data{'t'}{$class};
		++$data{$type}{'t'};
		++$data{'t'}{'t'};
	}

	for my $title ('Type', @Class) {
		printf "   %7s", $title;
	}
	print "\n".('-'x75)."\n";

	for my $type (@Types) {
		my $tk = lc(substr($type,0, 1));
		my $classes = $data{$tk};

		printf "%7s | ", $type;

		for my $class (@Class) {
			my $ck = lc(substr($class,0, 1));
			my $val = $classes->{$ck};
			$val ||= '';
	
			printf "   %7s", $val;
		}
		print "\n";
	}
}


1;
