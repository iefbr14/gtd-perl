package Hier::Sort;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( by_task by_goal );
}

use Carp;
use Hier::Tasks;
use Hier::Option;

our $Version = 1.0;

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
	age      => \&by_age,
	change   => \&by_change
);

my %Sort_cache;

sub sorter {
	my($by, $itemlist) = @_;

	###BUG### fetch command line option sort override
	if ($by =~ s/^\^// and !defined $Criteria{$by}) {
		die "Huh? sort '$by' unknown\n";
	}

	my $doby = $Criteria{$by};
	if (option('Reverse')) {
		return reverse sort { &$doby } @$itemlist;
	} else {
		return sort { &$doby } @$itemlist;
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
	my($a, $b) = @_;

	return $a->get_tid() <=> $a->get_tid();
}

sub By_hier {
	my($a, $b) = @_;

	return By_hier($a, $b) || By_task($a, $b);
}

sub by_hier {
die;
	###BUG### junk sub need to walk to hier
	return  $a->get_title() cmp $b->get_title()
	||      $a->get_tid() <=> $b->get_tid();
}

sub by_status {
	my($a, $b) = @_;

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
	my($a, $b) = @_;

	return $a->get_modified() cmp $b->get_modified();
}

sub by_age {
	my($a, $b) = @_;

	return $a->get_created() cmp $b->get_created();
}

sub by_Task {
	my($a, $b) = @_;

	return by_task($a,$b) || by_tid($a,$b);
}

sub by_task {
	my($a, $b) = @_;

	return $a->get_task() cmp $b->get_task();
}

sub by_pri {
	my($a, $b) = @_;

	# order by priority $order, created $order, due $order 

	my($rc)	= $a->get_priority() <=> $b->get_priority()
	||	  $a->get_created()  cmp $b->get_created()
	||	  $a->get_due()      cmp $b->get_due();

	return $rc;
}

sub by_doitdate {
	my($a, $b) = @_;

        my($ad) = $a->get_doit() || sprintf("-%06d", $a->get_tid());
        my($bd) = $b->get_doit() || sprintf("-%06d", $b->get_tid());

        return $ad cmp $bd;
}


sub by_goal {
	my($a, $b) = @_;
	return sort_goal($a) cmp sort_goal($b);
}

sub sort_goal {
	my($ref) = @_;

	my($tid) = $ref->get_tid();

	return $Sort_cache{$tid} if defined $Sort_cache{$tid};

	my(@list);
	for (;;) {
		unshift(@list, $ref->get_title(), $tid);
		last if $ref->get_type() eq 'g';
		$ref = $ref->get_parent;
		last if !defined $ref;
	}
	
	$Sort_cache{$tid} = join("\t", @list);

	return $Sort_cache{$tid};
}

1;
