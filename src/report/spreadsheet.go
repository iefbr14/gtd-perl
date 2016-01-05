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

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_spreadsheet);
}

use Hier::Util;
use Hier::Meta;
use Hier::Resource;

sub Report_spreadsheet {	#-- Project Summary for a role
	meta_filter('+active', '^tid', 'none');
	my @want = meta_argv(@_);

	if (@want == 0) {
		my($roles) = load_roles();
		foreach my $role (sort keys %$roles) {
			display_role($role, $roles->{$role});
		}
		return;
	}

	my($roles) = load_roles();
	foreach my $role (@want) {
		if (defined $roles->{$role}) {
			display_role($role, $roles->{$role});
		} else {
			warn "No such role: $role\n";
		}
	}
}


sub load_roles {
	my($role) = @_;

	my(%roles);

	# find all next and remember there projects
	for my $ref (meta_matching_type('o')) {
##FILTER	next if $ref->filtered();

		my $pid = $ref->get_tid();
		my $role = $ref->get_title();
		$role =~ s/ .*//;
		$role = ucfirst($role);
		$roles{$role} = $ref;
	}
	return \%roles;
}

sub display_role {
	my($role, $ref) = @_;

	print "\fGoal:$role\tProj-id\tProject\tItem-id\tNext-Action\tHours\tTotal-$role\n";

	my(@list);
	foreach my $gref ($ref->get_children()) {
		next if $gref->filtered();

		push(@list, get_projects($gref));
	}

	foreach my $line (sort {
		$a->[0] cmp $b->[0]
	   ||	$a->[2] cmp $b->[2]
	   ||	$a->[4] cmp $b->[4]
	} @list) {
		print join("\t", @$line), "\n";
	}
}

sub get_projects {
	my($gref) = @_;

	my(@list);

	foreach my $pref ($gref->get_children()) {
		next if $pref->filtered();

		push(@list, get_actions($gref, $pref));
	}
	return @list;
}

sub get_actions {
	my($gref, $pref) = @_;

	my($gtitle) = $gref->get_title();

	my($total) = 0;
	my($pid, $ptitle);
	my($tid, $title, $hours);
	foreach my $ref ($pref->get_children()) {
		next if $ref->filtered();

		my($resource) = new Hier::Resource($ref);
		my($effort) = $resource->hours();
		$effort = .5 unless $effort;

		unless ($tid) {
			$pid = $pref->get_tid();
			$ptitle = $pref->get_title();

			$tid = $ref->get_tid();
			$title = $ref->get_title();
			$hours = $effort;
		}
		$total += $effort;
	}

	unless ($tid) {
		$pid = $pref->get_tid();
		$ptitle = $pref->get_title();
		return [ $gtitle, $pid, $ptitle, '', '', 2, '' ];
	}
	return [ $gtitle, $pid, $ptitle, $tid, $title, $hours, $total];
}

1;  # don't forget to return a true value from the file
