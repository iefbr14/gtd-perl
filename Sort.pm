package Hier::Sort;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(sort_mode sort_tasks by_task by_goal by_goal_task );
}

use Carp;
use Hier::Option;

our $Version = 1.0;

sub by_hier($$);

my(@Criteria);
my(%Criteria) = (
	id	 => \&by_tid,
	tid	 => \&by_tid,
	task	 => \&by_task,
	title	 => \&by_task,
	hier	 => \&by_hier,
	status	 => \&by_status,
	focus    => \&by_focus,
	panic    => \&by_panic,
	pri	 => \&by_pri,
	priority => \&by_pri,
	doit     => \&by_doitdate,
	doitdate => \&by_doitdate,
	date     => \&by_age,
	age      => \&by_age,
	change   => \&by_change,
	rgpa     => \&by_goal_task,
	goaltask => \&by_goal_task,
);

my(%Meta_key);

my $Sorter = \&by_task;

sub sort_mode {
	my($mode) = @_;

	$mode =~ s/^\^//;	# default is asending 
	if ($mode =~ s/^\~//) {	# desending
		option('Reverse', 1);
	}
	$mode = lc($mode);

	unless (defined $Criteria{$mode}) {
		warn "Unknown Sort mode: $mode\n";
		return;
	}

	$Sorter = $Criteria{$mode};

	%Meta_key = ();		# clear any cached keys
}

sub sort_tasks {
	my($rev) = option('Reverse', 0);

	if ($rev) {
		return reverse sort { &$Sorter($a,$b) } @_;
	}
	
	return sort { &$Sorter($a,$b) } @_;
	## comment out prev line to Debug.
	my(@list) =  sort { &$Sorter($a,$b) } @_;

	for my $ref (@list) {
		my $tid = $ref->get_tid();
		my $title = lc_title($ref);

		my $key = $Meta_key{$tid} || '';
		print "$tid => $title\n";
	}
	return @list;
}

my %Sort_cache;

#sub sorter($$) {
#	my($by, $itemlist) = @_;
#
#	###BUG### fetch command line option sort override
#	if ($by =~ s/^\^// and !defined $Criteria{$by}) {
#		die "Huh? sort '$by' unknown\n";
#	}
#
#	my $doby = $Criteria{$by};
#	if (option('Reverse')) {
#		return reverse sort { &$doby($a, $b) } @$itemlist;
#	} else {
#		return sort { &$doby($a, $b) } @$itemlist;
#	}
#}

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

sub by_tid($$) {
	my($a, $b) = @_;

	return $a->get_tid() <=> $b->get_tid();
}

sub by_hier($$) {
	my($a, $b) = @_;

	my($pa) = $a->get_parent();
	my($pb) = $b->get_parent();

	if ($pa && $pb) {
		if ($pa != $pb) {
			return by_hier($pa, $pb);
		}
	} elsif ($pa) {
		return 1;
	} elsif ($pb) {
		return -1;
	}

	# no parents or parents equal
	return  lc_title($a) cmp lc_title($b)
	||      $a->get_tid() <=> $b->get_tid();
}

sub by_status($$) {
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

sub by_change($$) {
	my($a, $b) = @_;

	return $a->get_modified() cmp $b->get_modified();
}

sub by_age($$) {
	my($a, $b) = @_;

	return $a->get_created() cmp $b->get_created();
}

sub by_Task($$) {
	my($a, $b) = @_;

	return by_task($a,$b) || by_tid($a,$b);
}

sub by_task($$) {
	my($a, $b) = @_;

	return lc_title($a) cmp lc_title($b);
}

sub by_pri($$) {
	my($a, $b) = @_;

	# order by priority $order, created $order, due $order 

	my($rc)	= $a->get_priority() <=> $b->get_priority()
	||	  $a->get_created()  cmp $b->get_created()
	||	  $a->get_due()      cmp $b->get_due();

	return $rc;
}

sub by_doitdate($$) {
	my($a, $b) = @_;

        return sort_doit($a) cmp sort_doit($b);
}

sub sort_doit {
	my($ref) = @_;

	my($tid) = $ref->get_tid();
	return $Sort_cache{$tid} if defined $Sort_cache{$tid};

	my($v) = $ref->get_doit() || $ref->get_created();

	$Sort_cache{$tid} = $v;
	return $v;
}


sub by_goal($$) {
	my($a, $b) = @_;
	return sort_goal($a) cmp sort_goal($b);
}

sub sort_goal {
	my($ref) = @_;

	my($tid) = $ref->get_tid();

	return $Sort_cache{$tid} if defined $Sort_cache{$tid};

	my(@list);
	for (;;) {
		unshift(@list, lc_title($ref), $tid);
		last if $ref->get_type() eq 'g';
		$ref = $ref->get_parent;
		last if !defined $ref;
	}
	
	$Sort_cache{$tid} = join("\t", @list);

	return $Sort_cache{$tid};
}

sub by_goal_task($$) {
	my($a, $b) = @_;

	return Meta_key($a) cmp Meta_key($b);
}

sub Meta_key {
	my($ref) = @_;

	my($tid) = $ref->get_tid();

	my($val) = $Meta_key{$tid};
	return $val  if defined $val;

	my($title) = lc_title($ref);

	my($p_title) = '--';
	my($g_title) = '--';
	my($p_ref) = $ref->get_parent();
	if ($p_ref) {
		$p_title = lc_title($p_ref);
		my($g_ref) = $p_ref->get_parent();
		if ($g_ref) {
			$g_title = lc_title($g_ref);
		}
	} 
	$val = "$g_title\t$p_title\t$title\t$tid",  
	$Meta_key{$tid} = $val;
	return $val;
}

# next   norm  some  done 
# 012345 12345 12345
#  abcde fghij klmno z

sub item_focus {
	my($ref) = @_;

	my($pri) = $ref->get_priority();

	if ($ref->get_nextaction() eq 'y') {
		# cool
	} elsif ($ref->is_someday() eq 'y') {
		$pri += 10;
	} else {
		$pri += 5;
	}
	$pri = chr(ord('a') + $pri - 1);

	$pri = 'z' if $ref->get_completed();

	return $pri;
}

sub calc_focus {
	my($ref) = @_;

	unless (defined $ref) {
		return '';
	}

	my($tid) = $ref->get_tid();

	my($val) = $Meta_key{$tid};
	return $val  if defined $val;

	my($pri) = item_focus($ref);

	$val = calc_focus($ref->get_parent()) . $pri;
	$Meta_key{$tid} = $val;

	return $val;
}


sub by_focus($$) {
	my($a, $b) = @_;

	return calc_focus($a) cmp calc_focus($b);
}

# next   norm  some  done 
# 012345 12345 12345
#  abcde fghij klmno z

sub calc_panic {
	my($ref) = @_;

	unless (defined $ref) {
		return '';
	}

	my($tid) = $ref->get_tid();

	my($val) = $Meta_key{$tid};
	return $val if defined $val;

	$val = item_focus($ref);
	for my $child ($ref->get_children()) {
		my $pri = calc_panic($child);
		$val = $pri if $pri lt $val;
	}
	
	$Meta_key{$tid} = $val;

	return $val;
}



sub by_panic($$) {
	my($a, $b) = @_;

	return (calc_panic($a) cmp calc_panic($b))
	    || by_hier($a, $b);
}

sub lc_title {
	my($ref) = @_;

	my($title) = $ref->get_title();

	$title =~ s/\[\[//g;
	$title =~ s/\]\]//g;

	return lc($title);
}

1;
