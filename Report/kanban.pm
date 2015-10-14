package Hier::Report::kanban;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &Report_kanban );
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

my %States = (
	a => 'Analysis',
	c => 'Completed Analysis',
	d => 'Doing',
	f => 'Finished Doing',
	t => 'Test',
	w => 'Wiki update',
	z => 'Z all done', 		# should have a completed date
);

my @Class = qw(Done Someday Action Next Future Total);

use Hier::util;
use Hier::Meta;
use Hier::Format;
use Hier::Option;
use Hier::Resource;

my $Hours_task = 0;
my $Hours_next = 0;

sub Report_kanban {	#-- report kanban of projects/actions
	# counts use it and it give a context
	meta_filter('+active', '^tid', 'simple');	

	my(@list) = meta_pick(@_);

	if (@list == 0) {
		@list = meta_pick('roles');
	}
	check_roles(@list);

	my $proj = check_proj();
	my $task = check_task();
	my $next = check_next();
	my $hier = check_hier();

#	print "Options:\n";
#	for my $option (qw(pri debug db title report)) {
#		printf "%10s %s\n", $option, get_info($option);
#	}
#	print "\n";

	print "----------------\n";
	my($total) = $task + $next;
	print "hier: $hier, projects: $proj, next,actions: $next+$task = $total\n";

	my($t_p) = '-';
	my($t_a) = $Hours_task;
	my($t_n) = $Hours_next;

	my($time) = '?';
	print "time: $time, projects: $t_p, next,actions: $t_n,$t_a\n";
}

=head

We need to check in each role there is:

* only 1 project in analysis
* only 1 project in development
* only 1 project in test
* only 1 project in wiki wait
* and no projects in z that don't have completed date

=cut

sub check_hier {
	my($count) = 0;

	# find all hier records
	foreach my $ref (meta_all()) {
		next unless $ref->is_hier();
		next if $ref->filtered();

		if ($ref->get_state() eq 'z') {
			if ($ref->get_completed eq '') {
				print "To tag as done:\n" if $count == 0;
				display_task($ref);
				++$count;
			}
		}
	}
}

sub check_roles {
	foreach my $ref (@_) {
		display_rgpa($ref);

		check_a_role($ref);
	}
}

sub check_a_role {
	my($role_ref) = @_;

	my($anal);
	my($devel);
	my($test);
	my($wiki);

	for my $gref ($role_ref->get_children()) {
		for my $ref ($gref->get_children()) {
			my $state = $ref->get_state();

			unless ($state =~ m/[-acdftwz]/) {
				display_task($ref, "Unknown state $state");
				next;
			}

			check_state($ref, $state, 'a', \$anal);
			check_state($ref, $state, 'd', \$devel);
			check_state($ref, $state, 't', \$test);
			check_state($ref, $state, 'w', \$wiki);
		}
	}

	my($needs) = '';
	$needs .= ' analysys' unless $anal;
	$needs .= ' devel' unless $devel;
	$needs .= ' test' unless $test;
	$needs .= ' wiki' unless $wiki;

	display_task($role_ref, "\t|<<<Needs".$needs) if $needs;

	if ($anal) {
		print "A: "; display_task($anal)  
	}
	if ($devel) {
		print "D: "; display_task($devel) 
	}
	if ($test) {
		print "T: "; display_task($test)  
	}
	if ($wiki) {
		print "W: "; display_task($wiki)  
	}
}

sub check_state {
	my($ref, $state, $want, $var) = @_;

	return unless $state eq $want;

	if (defined $$var) {
		display_task($$var,  "\t|<<<$state>>");
		display_task($ref,   "\t|<<<$state>> also in state");
		return;
	}
	$$var = $ref;
}

sub check_proj {
	my($count) = 0;

	# find all projects
	foreach my $ref (meta_matching_type('p')) {

		++$count;
	}
	return $count;
}

sub check_liveproj {
	my($count) = 0;

	# find all projects
	foreach my $ref (meta_matching_type('p')) {
###FILTER	next if $ref->filtered();

		next unless project_live($ref);

		++$count;
	}
	return $count;
}

sub check_task {
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

sub check_next {
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

sub check_tasklive {
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


1;
