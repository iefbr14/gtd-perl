package Hier::Report::kanban;

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
	@EXPORT      = qw( &Report_kanban );
}

use Hier::Util;
use Hier::Color;
use Hier::Meta;
use Hier::Format;
use Hier::Option;
use Hier::Resource;

sub Report_kanban {	#-- report kanban of projects/actions
	# counts use it and it give a context
	meta_filter('+active', '^tid', 'simple');	

	my(@args);
	foreach my $arg (meta_argv(@_)) {
		if ($arg =~ s/^\.//) {
			kanban_bump($arg);
			next;
		}

		if ($arg =~ m/^(\d+)=(.)$/) {
			kanban_state($1, $2);
			next;
		}
		push(@args, $arg);
	}

	# done if we had args but all were processed
	if (scalar(@_) > 0 && scalar(@args) == 0) {
		return;
	}

	my(@list) = meta_pick(@args);

	if (@list == 0) {
		@list = meta_pick('roles');
	}
	check_roles(@list);

}

sub kanban_bump {
	my(@arg) = @_;

	my($fail) = 0;
	my(@list);
	while (@arg) {
		my($arg) = shift @arg;
		if ($arg =~ /,/) {
			push(@arg, split(/,/, $arg));
			next;
		}

		my($ref) = meta_find($arg);

		unless (defined $ref) {
			warn "Task $arg doesn't exits\n";
			$fail++;
			next;
		}
		push(@list, $ref);
		next;
	}
	die "Nothing bunped due to errors\n" if $fail;

	for my $ref (@list) {
		my($new) = Hier::Resource::bump($ref);

		if ($new) {
			my($name) = Hier::Resource::state($new);

			display_task($ref, "| now <<< $name >>>");
		} else {
			my($state) = $ref->get_state();

			display_task($ref, "|<<< unknown state $state");
		}
	}
}

sub kanban_state {
	my($tid, $state) = @_;

	my($ref) = meta_find($tid);

	unless (defined $ref) {
		die "Task $tid doesn't exits\n";
	}

	$ref->set_state($state);
}
	
sub check_hier {
	my($count) = 0;

	# find all hier records
	foreach my $ref (meta_all()) {
		next unless $ref->is_hier();
		next if $ref->filtered();

		if ($ref->get_state() eq 'z') {
			if ($ref->get_completed eq '') {
				print "To tag as done:\n" if $count == 0;
				display_task($ref, '(tag as done)');
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

	my(@anal);
	my(@devel);
	my(@ick);
	my(@test);
	my(@wiki);
	my(@repo);

	$| = 1;
	for my $gref ($role_ref->get_children()) {
		for my $ref ($gref->get_children()) {
			my $state = $ref->get_state();

			unless ($state =~ m/[-abcdfitrwz]/) {
				display_task($ref, "Unknown state $state");
				next;
			}
			check_title($ref) if $state ne '-';

			check_state($ref, $state, 'b', \@anal);
			check_state($ref, $state, 'd', \@devel);
			check_state($ref, $state, 'i', \@ick);
			check_state($ref, $state, 'r', \@repo);
			check_state($ref, $state, 't', \@test);
			check_state($ref, $state, 'u', \@wiki);
		}
	}

	my($needs) = '';
	$needs .= ' analysys' unless @anal;
	$needs .= ' devel' unless @devel;
	$needs .= ' test' unless @test;

	print_color('RED');
	display_task($role_ref, "\t|<<<Needs".$needs) if $needs;

	for my $anal (@anal) {
		print "A: "; display_task($anal, '(analyze)');
	}

	for my $devel (@devel) {
		print "D: "; display_task($devel, '(do)');
	}

	for my $ick (@ick) {
		print_color('CYAN');
		print "I: "; display_task($ick, '(ick)'); 
		print_color
	}

	for my $test (@test) {
		print "T: "; display_task($test, '(test)'); 
	}

	for my $repo (@repo) {
		print_color('BROWN');
		print "R: "; display_task($repo, '(reprocess/reprint wiki)');
	}

	for my $wiki (@wiki) {
		print_color('PURPLE');
		print "W: "; display_task($wiki, '(update wiki)');
	}
}

sub check_state {
	my($ref, $state, $want, $var) = @_;

	return unless $state eq $want;

	push(@{$var}, $ref);
}

sub check_title {
	my($pref) = @_;

	my($title) = $pref->get_title();

	if ($title =~ /\[\[.*\]\]/) {
		return;
	}

	display_task($pref, "\t| !!! no wiki title");
}

1;
