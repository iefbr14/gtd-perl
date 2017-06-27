package GTD::Filter;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &add_filter );
}

use GTD::Tasks;
use GTD::Option;

my $Filter_Category;
my $Filter_Context;
my $Filter_Timeframe;
my %Filter_Tags;

my $Today = get_today();
my $Soon  = get_today(+7);

my @Filters;	# types of actions to include
our $Debug = 0;

my $Default_level = 'm';

sub filtered_reason {
	my($ref) = @_;

	return $ref->{_filtered} || '';
}

sub filtered {
	my ($ref) = @_;

	my($reason) = filtered_reason($ref);

	if (substr($reason,0,1) eq '-') {
		if ($Debug) {
			my($tid) = $ref->get_tid();
			my($title) = $ref->get_title();
			print "X: $reason ($tid: $title)\n";
		}
		return $reason;
	}
	return '';
}

sub tasks_matching_type {
	my($type) = @_;

	return grep { $_->get_type() eq $type } GTD::Tasks::all();
}

sub reset_filters {
	my($filter) = @_;
}

sub apply_filters {
	#$Debug = option('Debug');

	# learn about actions
	for my $ref (tasks_matching_type('a')) {
		task_mask($ref);
	}

	# learn about projects
	for my $ref (tasks_matching_type('p')) {
		proj_mask($ref);
	}

	# walk down
	#      kill children
	# then on the way back up
	#      back fill hier with wanted items
	print "Default level $Default_level\n" if $Debug;
	for my $ref (tasks_matching_type($Default_level)) {
		apply_walk_down($ref);
	}
	for my $ref (GTD::Tasks::all()) {
		apply_walk_down($ref);
	}

	my($have_cct_filters)
	    = $Filter_Category
	   || $Filter_Context
	   || $Filter_Timeframe
	   || %Filter_Tags;

	if ($have_cct_filters) {
		for my $ref (tasks_matching_type('m')) {
			apply_cct_filters($ref);
		}
	}
}

sub apply_walk_down {
	my($ref) = @_;

	apply_ref_filters($ref);
	for my $child ($ref->get_children()) {
		apply_walk_down($child);
	}
}

#
# walk down the current valid hier
#    if we are wanted then
#       if one of our child is wanted we are still wanted.
#          else commit suicide taking our children with us.
#
sub apply_cct_filters {
	my($ref) = @_;

	# not wanted
	return 0 unless defined $ref->{_filtered};
	if ($ref->{_filtered} =~ /^-/) {
		return 0;
	}
	my($reason) = cct_wanted($ref);
	if ($reason) {
		if ($Debug) {
			warn "#=CCT($reason) ", $ref->get_tid(),
				": ", $ref->get_title(), "\n";
		}
		# we are the reason to live!
		return $reason;
	}

	my ($wanted) = 0;	# we are only wanted if our children are wanted
	for my $child ($ref->get_children()) {
		$reason = apply_cct_filters($child);
		if ($reason) {
			$wanted ||= $reason;
			if ($Debug) {
				warn "#+CCT($reason) ", $ref->get_tid(),
					": ", $ref->get_title(), "\n";
			}
		}
	}
	return $wanted if $wanted;
	kill_children($ref);
}

sub kill_children {
	my($ref) = @_;

	$ref->{_filtered} = '-cct';
	if ($Debug) {
		warn "#-CCT ", $ref->get_tid(),
			": ", $ref->get_title(), "\n";
	}
	for my $child ($ref->get_children()) {
		next if $child->{_filtered} && $child->{_filtered} =~ m/^-/;

		kill_children($child);
	}
}


###======================================================================
###
###======================================================================
# todo_id:        1889				id/type
# type:           a			[ ]
# nextaction:     n			[_]
# isSomeday:      y			{_}

# category:       Admin				context
# context:        Office
# timeframe:      Hour

# created:        2009-05-23			create/modified
# modified:       2009-05-23 16:02:04


# priority:       1				order/priority
# doit:           0000-00-00 00:00:00
# nexttask:	  1

# due:					[_]	due/done/delay
# completed:				[*]
# tickledate:				[~]

# task:           Billing			descriptions
# description:    Update billing
# note:

# recur:					repeats
# recurdesc:

# parent_id:      0				hier parents
# Parents:        425

###======================================================================
###======================================================================
#
# task filters:
#
use constant {
	A_MASK		=> 0x0000_00FF,	# action bits
	Z_MASK		=> 0x0000_0F00,	# timeframe hints
	T_MASK		=> 0x0000_F000,	# task type mask
	P_MASK		=> 0x00FF_0000,	# Parent mask


# done/next/current/later
	A_DONE		=> 0x01,
	A_NEXT		=> 0x02,
	A_ACTION	=> 0x04,
	#		=> 0x08,
	A_WAITING	=> 0x10,
	A_SOMEDAY	=> 0x20,
	A_TICKLE	=> 0x40,
	#_HIER		=> 0x80,

# timeframe hints
	Z_LATE		=> 0x0100,	# priority == 1
					# or Due < today

	Z_DUE           => 0x0200,	# priority == 2
					# or Due < week

	Z_SLOW		=> 0x0300,	# priority == 4
	Z_IDEA		=> 0x0400,	# priority == 5

# composite (from A_)
	T_NEXT		=> 0x1000,
	T_ACTIVE	=> 0x2000,
	T_FUTURE	=> 0x3000,
	T_DONE		=> 0x4000,

# project known
	P_FUTURE	=> 0x040_0000,	# is only in future
	P_DONE		=> 0x080_0000,	# is complete tagged as done

	G_LIVE  	=> 0x2000_0000,	# has live items
	G_FUTURE	=> 0x4000_0000,	# has future items
	G_DONE		=> 0x8000_0000,	# has done items

};

sub add_filter {
	my($rule) = @_;

	warn "#-Parse filter: $rule\n" if $Debug;

	if ($rule eq '~~') {
		warn "#-Filters reset\n" if $Debug;
		@Filters = ();
		return;
	}

	if ($rule =~ s/^~//) {	# tilde
		task_filter($rule, '!', '');
		return;
	}

	if ($rule =~ s/^\-//) {	# dash
		task_filter($rule, '-', '');
		return;
	}
	if ($rule =~ s/^\+=//) {
		task_filter($rule, '', '=');
		return;
	}

	if ($rule =~ s/^\+>//) {
		task_filter($rule, '', '>');
		return;
	}
	if ($rule =~ s/^\+<//) {
		task_filter($rule, '', '<');
		return;
	}
	if ($rule =~ s/^\+!//) {
		task_filter($rule, '!', '');
		return;
	}

	if ($rule =~ s/^\+//) {
		task_filter($rule, '', '');
		return;
	}

	warn "Unknown filter request: $rule\n";
}

sub dispflags {
	my($flags) = @_;

	return 'fook' unless defined $flags;

	my($z) = '.';
	my($t) = '.';

	#         654321
	my($a) = '------';
	#              Dn swt odsi

	substr($a, -1, 1) = 'x' if $flags & A_DONE;
	substr($a, -2, 1) = 'w' if $flags & A_WAITING;
	substr($a, -3, 1) = 's' if $flags & A_SOMEDAY;
	substr($a, -4, 1) = 't' if $flags & A_TICKLE;
	substr($a, -5, 1) = 'a' if $flags & A_ACTION;
	substr($a, -6, 1) = 'n' if $flags & A_NEXT;

	$t = 'x' if ($flags & T_MASK) == T_DONE;
	$t = 'f' if ($flags & T_MASK) == T_FUTURE;
	$t = 'a' if ($flags & T_MASK) == T_ACTIVE;
	$t = 'n' if ($flags & T_MASK) == T_NEXT;

	$z = 'l' if ($flags & Z_MASK) == Z_LATE;
	$z = 'd' if ($flags & Z_MASK) == Z_DUE;
	$z = 's' if ($flags & Z_MASK) == Z_SLOW;
	$z = 'i' if ($flags & Z_MASK) == Z_IDEA;

	my($p) = '--';

	substr($p,  0, 1) = 'F' if $flags & P_FUTURE;
	substr($p,  1, 1) = 'X' if $flags & P_DONE;

	my($g) = '---';
	substr($g,  0, 1) = 'l' if $flags & G_LIVE;
	substr($g,  1, 1) = 'f' if $flags & G_FUTURE;
	substr($g,  2, 1) = 'x' if $flags & G_DONE;

	return "$g.$p|$z.$t|$a";
	return "$g.$p|$z.$t|$a";
}

sub task_filter {
	my($name, $dir, $will) = @_;

	my($func, $walk, $arg) = map_filter_name($name);
	unless ($func) {
		warn "Warn unknown filter: $name\n";
		return;
	}

	warn "#-Filter $name: [$will,$walk,$dir] $arg\n" if $Debug;
	$walk = $will if $will;
	$walk = $dir unless $walk;
	$walk = '+' unless $walk;

	my($filter) = {
		func => $func,
		name => $name,
		dir  => $walk,
		arg  => $arg,
	};

	push(@Filters, $filter);
}

sub task_mask {
	my($ref) = @_;

	return $ref->{_mask} if defined $ref->{_mask};

	my($mask) = 0x0000;

	my($done) = $ref->is_completed();
	my($due)  = $ref->get_due();
	my($type) = $ref->get_type();

	$mask |= A_DONE		if $done;  # step on next/somday/tickle
	$mask |= A_SOMEDAY	if $ref->get_isSomeday() eq 'y';
	$mask |= A_TICKLE	if $ref->get_tickledate() gt $Today;
	$mask |= A_WAITING	if $type eq 'w';
	$mask |= A_NEXT	 	if $ref->get_nextaction() eq 'y';

	if ($type eq 'a') {
		$mask |= A_ACTION;
	}
	$ref->{_mask} = $mask;

	if ($mask & A_DONE) {
		$mask |= T_DONE;
		give_children($ref, P_DONE);

	} elsif ($mask & A_SOMEDAY || $mask & A_TICKLE || $mask & A_WAITING) {
		$mask |= T_FUTURE;
		give_children($ref, P_FUTURE);

	} elsif ($mask & A_NEXT) {
		$mask |= T_NEXT;
	} else {
		$mask |= T_ACTIVE;
	}

	unless ($done) {
		my($pri) = $ref->get_priority();
		my($hint) = 0;

		$hint = Z_LATE	if $pri == 1;
		$hint = Z_DUE	if $pri == 2;
		$hint = Z_SLOW	if $pri == 4;
		$hint = Z_IDEA	if $pri >= 5;

		if ($due) {
			$hint = Z_LATE	if $due lt $Today;
			$hint = Z_DUE	if $due ge $Today and $due le $Soon;
		}
		$mask |= $hint;
	}

	$ref->{_mask} = $mask;
	return $mask;
}

sub give_children {
	my($ref, $mask) = @_;

	for my $pref ($ref->get_children()) {
		$pref->{_mask} = task_mask($pref) | $mask;
		give_children($pref, $mask);
	}
}

sub give_parent {
	my($ref, $mask) = @_;

	for my $pref ($ref->get_parents()) {
		$pref->{_mask} = task_mask($pref) | $mask;
		give_parent($pref, $mask);
	}
}

sub task_mask_disp {
	my($ref) = @_;

	return dispflags(task_mask($ref));
}

sub proj_mask {
	my($ref) = @_;

	my($mask) = task_mask($ref);

	return if $mask & T_DONE;	# project tagged as done
	return if $mask & T_FUTURE;	# project yet to start

	###BUG### propigate done upward
	# check if all children are done
#	for my $cref ($ref->get_children()) {
#		next if task_mask($cref) & T_DONE;
#
#		return;
#	}
#	return 1;
}

sub meta_find_context {
	my($cct) = @_;
	my($Category) = GTD::CCT->Use('Category');
	my($Context) = GTD::CCT->Use('Context');
	my($Timeframe) = GTD::CCT->Use('Timeframe');

	# match case sensative first
	if ($Context->get($cct)) {
		warn "#-Set space context:  $cct\n" if $Debug;
		$Filter_Context = $cct;
		return;
	}
	if (defined $Timeframe->get($cct)) {
		warn "#-Set time context:   $cct\n" if $Debug;
		$Filter_Timeframe = $cct;
		return;
	}
	if (defined $Category->get($cct)) {
		warn "#-Set category:       $cct\n" if $Debug;
		$Filter_Category = $cct;
		return;
	}
	for my $key (GTD::CCT::keys('Tag')) {
		next unless $key eq $cct;

		warn "#-Set tag:            $key\n" if $Debug;
		$Filter_Tags{$key}++;
		return;
	}

	# match case insensative next
	for my $key ($Context->keys()) {
		next unless lc($key) eq lc($cct);

		warn "#-Set space context:  $key\n" if $Debug;
		$Filter_Context = $key;
		return;
	}
	for my $key ($Timeframe->keys()) {
		next unless lc($key) eq lc($cct);

		warn "#-Set time context:   $key\n" if $Debug;
		$Filter_Timeframe = $key;
		return;
	}
	for my $key ($Category->keys()) {
		next unless lc($key) eq lc($cct);

		warn "#-Set category:       $key\n" if $Debug;
		$Filter_Category = $key;
		return;
	}
	for my $key (GTD::CCT::keys('Tag')) {
		next unless lc($key) eq lc($cct);

		warn "#-Set tag:            $key\n" if $Debug;
		$Filter_Tags{$key}++;
		return;
	}

	warn "Defaulted category: $cct\n";
	$Filter_Category = $cct;
}

sub cct_wanted {
	my ($ref) = @_;

	if (%Filter_Tags) {
		for my $tag ($ref->get_tags()) {
			return "tag $tag" if exists $Filter_Tags{$tag}
			                  &&        $Filter_Tags{$tag};
		}
	}

	if ($ref->get_type() eq 'p' or $ref->is_task()) {
		if ($Filter_Context) {
			return "context $Filter_Context" if $ref->get_context() eq $Filter_Context;
		}
	}
	if ($Filter_Timeframe) {
		return "timeframe $Filter_Timeframe" if $ref->get_timeframe() eq $Filter_Timeframe;
	}
	if ($Filter_Category) {
		return "category $Filter_Category" if $ref->get_category() eq $Filter_Category;
	}


	return '';
}

sub add_filter_tags {
	if (option('Tag')) {
		for my $tag (split(',', option('Tag'))) {
			$Filter_Tags{$tag}++;
		}
	}
}

#******************************************************************************
#******************************************************************************
#******************************************************************************
#******************************************************************************
#******************************************************************************
sub map_filter_name {
	my($word, $dir) = @_;

	if ($word =~ s/^([a-z])://) {
		$Default_level = $1;
	}

	return (\&filter_any, '=', '*')	if $word =~ /^any/i;
	return (\&filter_any, '=', '=')	if $word =~ /^all/i;
	return (\&filter_any, '=', 'l')	if $word =~ /^list/i;
	return (\&filter_any, '=', 'h')	if $word =~ /^hier/i;
	return (\&filter_any, '=', 't')	if $word =~ /^task/i;


	return (\&filter_done, '>','')	if $word =~ /^done/i;
	return (\&filter_some, '>','')	if $word =~ /^some/i;
	return (\&filter_some, '>','')	if $word =~ /^maybe/i;

	return (\&filter_task, '<','')	if $word =~ /^action/i;
#	return (\&filter_next, '<','')	if $word =~ /^pure_next/i;
# we need to re-thing this live-next vs next

	return (\&filter_next, '><','')	if $word =~ /^next/i;
	return (\&filter_active, '><','')	if $word =~ /^active/i;
	return (\&filter_live, '><','')	if $word =~ /^live/i;
	return (\&filter_dead, '><','')	if $word =~ /^dead/i;
	return (\&filter_idle, '><','')	if $word =~ /^idle/i;

	return (\&filter_wait, '<','')	if $word =~ /^wait/i;
	return (\&filter_wait, '<','')	if $word =~ /^tickle/i;
	return (\&filter_late, '<','')	if $word =~ /^late/i;
	return (\&filter_due,  '<','')	if $word =~ /^due/i;

	return (\&filter_slow, '<','')	if $word =~ /^slow/i;
	return (\&filter_idea, '<','')	if $word =~ /^idea/i;


	return 0;
}

sub apply_ref_filters {
	my($ref) = @_;

	my($reason) = $ref->{_filtered};

	return $reason if $reason;

	for my $filter (@Filters) {
		my($func) = $filter->{func};
		my($dir)  = $filter->{dir};
		my($arg)  = $filter->{arg};

		$reason = &$func($ref, $arg);

		if ($Debug) {
			my($tid) = $ref->get_tid();
			my($title) = $ref->get_title();
			my($name) = $filter->{name};
			warn "#?Filter($name): $reason apply $dir for $tid: $title\n";
		}

		next if substr($reason, 0, 1) eq '?';

		if ($dir eq '=') {
			$ref->{_filtered} = $reason;
			return;
		}

		if ($dir eq '!') {
			$reason =~ tr/+-/-+/;
			$ref->{_filtered} = $reason;
			return;
		}

		if ($dir eq '<') {
			filter_walk_up($ref, $reason);
		} elsif ($dir eq '>') {
			filter_walk_down($ref, $reason);
		} elsif ($dir eq '<>') {
			filter_walk_up_down($ref, $reason);
		} elsif ($dir eq '><') {
			filter_walk_down_up($ref, $reason);
		}
		return;
	}
}

sub filter_walk_up {
	my($ref, $reason) = @_;

	my($mask) = $ref->{_filtered};

	return if $mask;	# already decided.

	$ref->{_filtered} = $reason;
	for my $pref ($ref->get_parents()) {
		filter_walk_up($pref, $reason.'<');
	}
}

sub filter_walk_up_down {
	my($ref, $reason) = @_;

	my($mask) = $ref->{_filtered};

	return if $mask;	# already decided.

	if ($reason =~ /^\+/) {
		for my $pref ($ref->get_parents()) {
			filter_walk_up($pref, $reason.'<');
		}
	}
	$ref->{_filtered} = $reason;
	for my $pref ($ref->get_children()) {
		filter_walk_down($pref, $reason.'>');
	}
}

sub filter_walk_down {
	my($ref, $reason) = @_;

	my($mask) = $ref->{_filtered};

	return if $mask;	# already decided.

	$ref->{_filtered} = $reason;
	for my $pref ($ref->get_children()) {
		filter_walk_down($pref, $reason.'>');
	}
}
sub filter_walk_down_up {
	my($ref, $reason) = @_;

	my($mask) = $ref->{_filtered};

	return if $mask;	# already decided.

	for my $pref ($ref->get_children()) {
		filter_walk_down($pref, $reason.'>');
	}
	$ref->{_filtered} = $reason;

	return if $reason =~ /^-/;

	for my $pref ($ref->get_parents()) {
		filter_walk_up($pref, $reason.'<');
	}
}

# return + if wanted
# return - if unwanted
# return ? if unknown

sub filter_any {
	my($ref, $arg) = @_;

	my($type) = $ref->get_type();

	if ($arg eq '*') {
		return "+any=".$type;
	}
	if ($arg eq '=') {
		return "+any=".$type unless $ref->is_list();
	}
	return "+any=$type" if $arg eq 't' && $ref->is_task();
	return "+any=$type" if $arg eq 'h' && $ref->is_hier();
	return "+any=$type" if $arg eq 'l' && $ref->is_list();

	return '?';
}

sub filter_task {
	my($ref, $arg) = @_;

	return '?' unless $ref->is_task();
	return '+task';
}

sub filter_done {
	my($ref, $arg) = @_;

	return '+done' if $ref->is_completed();
	return '?';
}


sub filter_pure_next {
	my($ref, $arg) = @_;

	return '?' unless $ref->is_task();
	return '+next' if $ref->get_nextaction() eq 'y';
	return '?';
}


sub filter_tickle {
	my($ref, $arg) = @_;

	return '+tickle' if $ref->get_tickle();
	return '?';
}

sub filter_wait {
	my($ref, $arg) = @_;

	my($type) = $ref->get_type();
	return '+wait' if $type eq 'w';
	return '?';
}


sub filter_late {
	my($ref, $arg) = @_;

	my($due)  = $ref->get_due();
	return '?' unless $due;

	if ($due le $Today) {
		return '+late'.$due;
	}
	return '?';
}


sub filter_due {
	my($ref, $arg) = @_;

	my($due)  = $ref->get_due();
	return '?' unless $due;

	if ($due ge $Today and $due le $Soon) {
		return '+due'.$due;
	}
	return '?';
}


sub filter_slow {
	my($ref, $arg) = @_;

	my($pri) = $ref->get_priority();
	return '+slow' if $pri == 4;
	return '?';
}


sub filter_idea {
	my($ref, $arg) = @_;

	my($pri) = $ref->get_priority();
	return '+idea' if $pri == 5;
	return '?';
}


sub filter_some {
	my($ref, $arg) = @_;

	my($mask) = task_mask($ref);
	return '+some' if ($mask & T_MASK) == T_FUTURE;
	return '?';
}

sub filter_next {
	my($ref, $arg) = @_;

	my($mask) = task_mask($ref);

	if ($ref->is_task()) {
		return '+live=n' if ($mask & T_MASK) == T_NEXT;
	} else {
		return filter_live($ref, $arg);
	}

	return '?';
}

sub filter_active {
	my($ref, $arg) = @_;


#	return '?' unless $ref->is_task();

	my($mask) = task_mask($ref);

	return '-act=d' if ($mask & A_MASK) == A_DONE;
	return '-act=s' if ($mask & A_MASK) == A_SOMEDAY;
	return '-act=t' if ($mask & A_MASK) == A_TICKLE;
	return '-act=w' if ($mask & A_MASK) == A_WAITING;

	if ($ref->is_task()) {
		return '+act=n' if ($mask & T_MASK) == T_NEXT;
		return '+act=a' if ($mask & T_MASK) == T_ACTIVE;
	}

	return '?';
}

sub filter_live {
	my($ref, $arg) = @_;


#	return '?' unless $ref->is_task();

	my($mask) = task_mask($ref);

	return '-live=d' if ($mask & A_MASK) == A_DONE;

	if ($ref->is_task()) {
		return '+live=n' if ($mask & T_MASK) == T_NEXT;
		return '+live=a' if ($mask & T_MASK) == T_ACTIVE;
		return '+live=f' if ($mask & T_MASK) == T_FUTURE;
	}

	return '?';
}


sub filter_dead {
	my($ref, $arg) = @_;

	return '?' unless $ref->is_task();

	my($mask) = task_mask($ref);
	return '+dead=d' if ($mask & T_MASK) == T_DONE;
	return '?';
}

sub filter_category {
	my($ref, $arg) = @_;

	my($category) = $ref->get_category() || '';
	return "+category=$arg" if lc($category) eq lc($arg);
	return '?';
}

sub filter_context {
	my($ref, $arg) = @_;

	my($context) = $ref->get_context() || '';
	return "+context=$arg" if lc($context) eq lc($arg);
	return '?';
}

sub filter_timeframe {
	my($ref, $arg) = @_;

	my($timeframe) = $ref->get_timeframe() || '';
	return "+timeframe=$arg" if lc($timeframe) eq lc($arg);
	return '?';
}

sub filter_tags {
	my($ref, $arg) = @_;

	for my $tag ($ref->get_tags()) {
		return "+tag=$tag" if lc($arg) eq lc($tag);
	}
	return '?';
}

1;
