package Hier::Sort;

use strict;
use warnings;

use base qw(Hier::Tasks);

our $Version = 1.0;

use Hier::util;
use Hier::Tasks;

my(@Criteria);
my(%Criteria) = (
	tid	 => \&by_tid,
	task	 => \&by_task,
	title	 => \&by_task,
	hier	 => \&by_hier,
	status	 => \&by_status,
	pri	 => \&by_pri,
	priority => \&by_pri,
	doitdate => \&by_doitdate,
);

sub sorted {
	my($by) = @_;

	my(@ref) = Hier::Tasks::all();

	###BUG### fetch command line option sort override
	if ($by =~ s/^\^// and !defined $Criteria{$by}) {
		die "Huh? sort '$by' unknown\n";
	}

	my $doby = $Criteria{$by};
	if (option('Reverse')) {
		return reverse sort { &$doby } @ref;
	} else {
		return sort { &$doby } @ref;
	}
}

sub sort_by {
	my($criteria) = @_;

	for my $criteria (@_) {
		push @Criteria, $criteria;
	}
	###BUG### make by_Sort an eval?
}

sub by_Sort {
#	for my $criteria (@critera) {
#		if ($criteria eq 
#	}
	return by_tid();
}

sub by_tid {
	return $a->get_tid() <=> $a->get_tid();
}

sub By_hier {
die;
	return By_hier() || By_task();
}

sub by_hier {
die;
	###BUG### junk sub need to walk to hier
	return  $a->get_title() cmp $b->get_title()
	||      $a->get_tid() <=> $b->get_tid();
}

sub by_status {
	my $ac = $a->get_completed();
	my $bc = $b->get_completed();

	if ($ac and $bc) {
		return $ac cmp $bc;
	}

	return -1 if $ac;	# a completed but not b, sort early
	return  1 if $bc;	# b completed but not a, sort late

	return 0;
}

sub by_change {
	return $a->get_modified() cmp $b->get_modified();
}

sub by_age {
	return $a->get_created() cmp $b->get_created();
}

sub by_Task {
	return by_task($a,$b) || by_tid($a,$b);
}

sub by_task {
	return $a->get_task() cmp $b->get_task();
}

sub by_pri {

	# order by priority $order, created $order, due $order 

	my($rc)	= $a->get_priority() <=> $b->get_priority()
	||	  $a->get_created()  cmp $b->get_created()
	||	  $a->get_due()      cmp $b->get_due();

	return $rc;
}

sub by_doitdate {
#       my($a, $b) = @_;

        my($ad) = $a->get_doit() || sprintf("-%06d", $a->get_tid());
        my($bd) = $b->get_doit() || sprintf("-%06d", $b->get_tid());

        return $ad cmp $bd;
}

1;
