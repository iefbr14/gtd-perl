package Hier::Report::board;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &Report_board );
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
use Hier::Color;

my $Hours_task = 0;
my $Hours_next = 0;

my $Cols;

sub Report_board {	#-- report board of projects/actions
	# counts use it and it give a context
	meta_filter('+active', '^tid', 'simple');	

	my(@list) = meta_pick(@_);

	if (@list == 0) {
		@list = meta_pick('roles');
	}

	$Cols = int(columns()/4)-(1+5+1);

	### printf "Columns: %s split %s\n", columns(), $Cols;

	check_roles(@list);

}

=head

For each role display:

Anal  |  Doing    |  Test | Done

Each column

TID: Keyword

Colors:

Green: inprogress

=cut

sub check_roles {
	foreach my $ref (@_) {
		check_a_role($ref);
	}
}

sub check_a_role {
	my($role_ref) = @_;

	my($anal,  @anal);
	my($devel, @devel);
	my($test,  @test);
	my($done,  @done);

	for my $gref ($role_ref->get_children()) {
		for my $ref ($gref->get_children()) {
			my $state = $ref->get_state();

			check_group($ref, $state, '-', \@anal);
			check_state($ref, $state, 'a', \$anal);

			check_group($ref, $state, 'c', \@devel);
			check_state($ref, $state, 'd', \$devel);

			check_group($ref, $state, 'f', \@test);
			check_state($ref, $state, 't', \$test);

			check_group($ref, $state, 'w', \@done);
			check_state($ref, $state, 'z', \$done);
		}
	}

	display_rgpa($role_ref);

	color('BOLD');
	printf("----- %-${Cols}s ", "Analyse");
	printf("----- %-${Cols}s ", "Devel");
	printf("----- %-${Cols}s ", "Test");
	printf("----- %s\n", "Complete");
	color();

	color('GREEN'); col($anal,  ' ', 1);
	color('GREEN'); col($devel, ' ', 2);
	color('GREEN'); col($test,  ' ', 2);
	color('GREEN'); col($done, "\n", 3);
	color();

	my($lines) = lines() - 5;
	while (scalar(@anal)
	    || scalar(@devel)
	    || scalar(@test)
	    || scalar(@done)
		) {

		col(shift @anal,  ' ' ,1);
		col(shift @devel, ' ', 2);
		col(shift @test,  ' ', 2);
		col(shift @done, "\n", 3);

		if (--$lines <= 0) {
			print "----- more ----\n";
			last;
		}
	}
}

sub col {
	my($ref, $sep, $how) = @_;

	unless ($ref) {
		printf("%5s %-${Cols}.${Cols}s%s", '', '', $sep);
		return;
	}
	if ($how == 1) {
		check_empty($ref);

	} elsif ($how == 2) {
		check_children($ref);

	} elsif ($how == 3) {
		check_done($ref);
	}

	my($tid) = $ref->get_tid();
	my($title) = $ref->get_title();

	$title =~ s/\[\[//g;
	$title =~ s/\]\]//g;

	printf("%5d %-${Cols}.${Cols}s%s", $tid, $title, $sep);

	color();
}

sub check_empty {
	my($pref) = @_;

	return unless $pref;

	for my $ref ($pref->get_children()) {
		next if $ref->get_completed();
		
		color('PINK');
		return;
	}
}

sub check_done {
	my($pref) = @_;

	return unless $pref;

	for my $ref ($pref->get_children()) {
		next unless $ref->get_completed();
		
		color('BROWN');
		return;
	}
}

sub check_children {
	my($pref) = @_;

	my($count) = 0;
	my($next) = 0;
	my($done) = 0;

	for my $ref ($pref->get_children()) {
		++$count;
		if ($ref->is_nextaction()) {
			++$next;
		}
		if ($ref->get_completed()) {
			++$done;
		}
	}

	if ($count == 0) {
		color('RED');
		return;
	}
	if ($next <= 0) {
		color('RED');
	}

	if ($count == $done) {
		color('PURPLE');
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

sub check_group {
	my($ref, $state, $want, $var) = @_;

	return unless $state eq $want;

	push(@{$var}, $ref);
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
