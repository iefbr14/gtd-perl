package Hier::Selection;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &add_pattern &add_selection &parent_filtered );
}

use Hier::Tasks;

my @Hier;

my @Filter_Parents;

sub add_patern {
	my($pat) = @_;

	$pat =~ s=/$==;	# remove trailing /

	for my $ref (Hier::Tasks::hier()) {
		my($title) = $ref->get_title();
		if ($title =~ /$pat/i) {
			my($tid) = $ref->get_tid();
			push(@Filter_Parents, $tid);
			warn "Parent($tid): $title\n";
		}
	}
}

sub add_selection {
	my($pat) = @_;	# first by case match

	my($found) = 0;

	if ($pat =~ m/^\d+$/) {
		my($tid) = $1;

		my $ref = Hier::Tasks::find($tid);

		if ($ref) {
			add_tree($ref);
		} else {
			warn "No such task id $tid\n";
		}
		return;
	}

	for my $ref (Hier::Tasks::hier()) {
		my($title) = $ref->get_title();

		if ($title eq $pat) {
			my($tid) = $ref->get_tid();
			add_tree($ref);
			warn "Parent($tid): $title\n";
			$found = 1;
		}
	}
	return if $found;		# got at least one

	$pat = lc($pat);		# ok try case insensative.

	for my $ref (Hier::Tasks::hier()) {
		my($title) = lc($ref->get_title());

		if ($title eq $pat) {
			my($tid) = $ref->get_tid();
			add_tree($ref);
			warn "Parent($tid): $title\n";
			last;
		}
	}
}

sub add_tree {
	my($tid) = @_;

	push(@Filter_Parents, $tid);
}

sub parent_filtered {
	my($ref) = @_;

	if (@Filter_Parents) {
		foreach my $tid (@Filter_Parents) {
			return 0 if ($ref->has_parent_id($tid));
		}
		warn "parent filtered\n";
		return 1;
	}
	return 0;
}

1;
