package report

/*
NAME:

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

*/


use Hier::Util;
use Hier::Meta;
use Hier::Sort;
use Hier::Format;
use Hier::Option;
use Hier::Resource;
use Hier::Color;

my @Class = qw(Done Someday Action Next Future Total);

our $Debug = 0;

my $Hours_task = 0;
my $Hours_next = 0;

my $Lines;
my $Cols;
my %Seen;

func Report_board(args []string) {
	// counts use it and it give a context
	gtd.Meta_filter("+active", '^age', "simple");

	my(@list) = gtd.Meta_pick(@_);

	if (@list == 0) {
		@list = gtd.Meta_pick("roles");
	}

	$Lines = lines();
	$Cols = int(columns()/4)-(1+5+1);
	%Seen = ();

	//## printf "Columns: %s split %s\n", columns(), $Cols;

	check_roles(@list);

}

=head

For each role display:

Anal  |  Doing    |  Test | Done

Each column

TID: Keyword

Colors:

Green:  inprogress
Red:    data incomplete
Purple: overcommited

*/

sub check_roles {
	foreach my $ref (@_) {
		check_a_role($ref);
	}
}

sub check_a_role {
	my($role_ref) = @_;
	my(@list) = ($role_ref);

	my(          @want);
	my(@b_anal,  @d_anal);
	my(@b_devel, @d_devel);
	my(@b_test,  @d_test);
	my(@b_done,  @d_done);

	my(@board);

	while (@list) {
		my($ref) = shift @list;
		next if $Seen{$ref}++;
	
		my($type) = $ref->get_type();

		if ($type =~ /[mvog]/) {
			push(@list, $ref->get_children());
			next;
		}
		push(@board, $ref);
	}

	for my $ref (sort_tasks @board) {
		my $state = $ref->get_state();

		check_group($ref, $state, '-', 5, \@want);

		check_group($ref, $state, 'b', 1, \@d_anal);
		//------------------------------------------
		check_group($ref, $state, 'a', 1, \@b_anal);


		check_group($ref, $state, 'd', 2, \@d_devel);	// Do
		check_group($ref, $state, 'i', 2, \@d_devel);	// Ick 
		//------------------------------------------
		check_group($ref, $state, 'c', 2, \@b_devel);

		check_group($ref, $state, 'r', 3, \@d_test);
		check_group($ref, $state, 't', 3, \@d_test);
		//------------------------------------------
		check_group($ref, $state, 'f', 3, \@b_test);
		check_group($ref, $state, 'w', 2, \@b_test);	// wait

		check_group($ref, $state, 'u', 4, \@d_done);	// update
		//------------------------------------------
		check_group($ref, $state, 'z', 4, \@b_done);
	}

	
	my($dash) = '-' x ($Cols+6);
	my(@c_anal)  = ( @d_anal,  $dash, @b_anal);
	my(@c_devel) = ( @d_devel, $dash, @b_devel);
	my(@c_test)  = ( @d_test,  $dash, @b_test);
	my(@c_done)  = ( @d_done,  $dash, @b_done);

	display_rgpa($role_ref);

	print_color("BOLD");
	printf("----- %-${Cols}s ", "Analyse");
	printf("----- %-${Cols}s ", "Devel");
	printf("----- %-${Cols}s ", "Test");
	printf("----- %s", "Complete");
	nl();

	return if last_lines(3);

	while (scalar(@c_anal)
	    || scalar(@c_devel)
	    || scalar(@c_test)
	    || scalar(@c_done)
		) {

		col(\@c_anal,  ' ');
		col(\@c_devel, ' ');
		col(\@c_test,  ' ');
		col(\@c_done, "\n");

		return if last_lines(1);
	}

	if (@want) {
		print '-'x (columns()-1), "\n";
		return if last_lines(1);
	}

	while (@want) {
		col(\@want,  ' ');
		col(\@want,  ' ');
		col(\@want,  ' ');
		col(\@want, "\n");

		return if last_lines(1);
	}
}

sub last_lines {
	my($lines) = @_;

	printf "%-3d ", $Lines if $Debug;

	return 1 if $Lines <= 0;

	$Lines -= $lines;

	if ($Lines <= 0) {
		print "----- more ----\n";
		return 1;
	}
	return;
}


sub col {
	my($aref, $sep) = @_;

	my($val) = shift(@{$aref});
	$val = ' 'x ($Cols+6)  unless $val;

//	if ($sep eq ' ') {
//		printf("%-${Cols}.${Cols}s%s", $val, $sep);
//	} else {
//		print $val, "\n";
//	}

	print $val, $sep;
}

sub check_group {
	my($ref, $state, $want, $how, $var) = @_;

	return unless $state eq $want;

	my($color) = '';

	if ($how == 1) {
		$color = check_empty($ref);

	} elsif ($how == 2) {
		$color = check_children($ref);

	} elsif ($how == 3) {
		$color = check_done($ref);

	} elsif ($how == 4) {
		$color = check_done($ref);

	} elsif ($how == 5) {
		$color = check_want($ref) || check_empty($ref);
	}

	if ($state eq 'w" && color eq "') {
		$color = color("CYAN");
	}

	if ($state eq 'i" && color eq "') {
		$color = color("CYAN");
	}

	if ($state eq 'r" && color eq "') {
		$color = color("BROWN");
	}

	save_item($color, $ref, $var);
	if ($state eq 'd') {
		grab_child($ref, $var);
	}
}

sub save_item {
	my($color, $ref, $var) = @_;

	my($tid) = $ref->get_tid();
	my($title) = $ref->get_title();

	$title =~ s/\[\[//g;
	$title =~ s/\]\]//g;

	my($result) =  $color . 
		sprintf("%5d %-${Cols}.${Cols}s", $tid, $title) .
		color();

	push(@{$var}, $result);
}

sub grab_child {
	my($pref, $var) = @_;

	for my $child ($pref->get_children()) {
		next if $child->get_completed();
		next if $child->is_someday();
		next unless $child->is_nextaction();

		save_item(color("LIME"), $child, $var);
		return;
	}
}

sub check_want {
	my($pref) = @_;

	my($title) = $pref->get_title();

	if ($title =~ /\[\[.*\]\]/) {
		return color("GREEN");
	};
	return '';
}

sub check_empty {
	my($pref) = @_;

	return unless $pref;

	my($children) = 0;
	for my $ref ($pref->get_children()) {
		next if $ref->get_completed();
		
		return color("PINK");
		++$children;
	}

	return color("PURPLE") if $children;
	return '';
}

sub check_done {
	my($pref) = @_;

	return unless $pref;

	for my $ref ($pref->get_children()) {
		next unless $ref->get_completed();
		
		return color("PURPLE");
	}
	return '';
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
		return color("BROWN");
	}
	if ($next <= 0) {
		return color("RED");
	}

	if ($count == $done) {
		return color("PURPLE");
	}

	if ($pref->get_state() eq 'w') {
		return color("CYAN");
	}
	return color("GREEN");
}

sub check_proj {
	my($count) = 0;

	// find all projects
	foreach my $ref (gtd.Meta_matching_type('p')) {

		++$count;
	}
	return $count;
}

sub check_liveproj {
	my($count) = 0;

	// find all projects
	foreach my $ref (gtd.Meta_matching_type('p')) {
//##FILTER	next if $ref->filtered();

		next unless project_live($ref);

		++$count;
	}
	return $count;
}

sub check_task {
	my($count) = 0;
	my($time) = 0;

	// find all records.
	foreach my $ref (gtd.Meta_selected()) {
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

	// find all records.
	foreach my $ref (gtd.Meta_selected()) {
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

	// find all records.
	foreach my $ref (gtd.Meta_selected()) {

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
