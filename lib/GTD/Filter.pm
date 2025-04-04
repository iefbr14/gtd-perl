package GTD::Filter;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &filter_Add &add_filter );
}

use Carp qw(cluck);

use GTD::Tasks;
use GTD::Option;

my @CCT_Filters = ();	# [ field, value, result-if-matched ]

my $Today = get_today();
my $Soon  = get_today(+7);

my @Rule_Filters;	# [ level, function, arg ]
our $Debug = 0;

my $Default_level = 'm';
my $Default_class = '*';
my $Default_active = '+a:live';

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
#			print "X: $reason ($tid: $title)\n";
		}
		return $reason;
	}
	return '';
}

sub tasks_matching_type {
	my($type) = @_;

	cluck("tasks_matching_type: type undefined ($type)") unless defined $type;

	return grep { 
	cluck("tasks_matching_type: type undefined ($type)") unless defined $type;
	$_->get_type() eq $type 
	} GTD::Tasks::all();
}

sub reset_filters {
	my($filter) = @_;

	for my $ref (GTD::Tasks::all()) {
		$ref->{_filtered} = '';
	}
	@Rule_Filters = ();
	@CCT_Filters = ();

	$Default_class = '*';
	$Default_level = 'm';
	$Default_active = '+a:live';
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

	
	# apply default class
#	for my $ref (GTD::Tasks::any()) {
#	}


	# apply default filter
	if (scalar(@Rule_Filters) == 0) {
		filter_Add($Default_active);
	}

	# apply all Rule filters
	for my $filter (@Rule_Filters) {
		my($type) = $filter->{type};
		my($func) = $filter->{func};

		for my $ref (tasks_matching_type($type)) {
			next if $ref->{_filtered};

			my($reason) = &$func($ref);

			$ref->{_filtered} = $reason;
		}
	}

	# walk down
	#      kill children
	# then on the way back up
	#      back fill hier with wanted items

	for my $ref (tasks_matching_type('m')) {
		apply_walk_down($ref, '');
	}

}

sub apply_walk_down {
	my($ref, $reason) = @_;

	if ($ref->{_filtered}) {
		$reason = $ref->{_filtered};

	} else {
		# check for cct and use that if it exists
		my ($cct) = apply_cct_filters($ref);

		if ($cct) {
			$reason = "$cct $reason";
		}

	}

	my(@children) = $ref->get_children();

	my($has_wanted) = 0;

	for my $child (@children) {
		my($child_reason) = apply_walk_down($child, $reason);

		++$has_wanted if $child_reason =~ /^\+/;
	}

	if ($has_wanted == 0) {
		$ref->{_filtered} ||= '-children';
	} else {
		$ref->{_filtered} ||= $reason || '+children';
	}
	return $ref->{_filtered};
}

#
# walk down the current valid hier
#    if we are wanted then
#       if one of our child is wanted we are still wanted.
#          else commit suicide taking our children with us.
#
sub apply_cct_filters {
	my($ref) = @_;

	return '' unless @CCT_Filters;

	for my $filter (@CCT_Filters) {
		my($field, $value, $result) = @$filter;

		my($match) = cct_match($ref, $field, $value);

		if ($Debug) {
			printf "#CCT %-8.8s : %s==%s => %s %d: %s\n",
				$match, $field , $value, $result,
				$ref->get_tid(), $ref->get_title();
		}

		return $result if $match;
	}
	return '';
}

sub cct_match {
	my ($ref, $field, $value) = @_;

	# wild card match any
	if ($value eq '*') {
		return '*' if $ref->get_type() =~ /^[gpa]/;
	}

	if ($field eq 'tag') {
		for my $tag ($ref->get_tags()) {
			return $tag if $tag eq $value;
		}
	}

	if ($field eq "context") {
		return "context" if $ref->ref_context() eq $value;
	}

	if ($field eq "timeframe") {
		return "timeframe" if $ref->ref_timeframe() eq $value;
	}

	if ($field eq "category") {
		return "category" if $ref->ref_category() eq $value;
	}

	return '';
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

	Z_IDEA		=> 0x0400,	# priority >= 5
					# or Due > year

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

sub add_filter { return filter_Add(@_) }

sub filter_Add {
	my($rule) = @_;

	warn "#-Parse filter: $rule\n" if $Debug;

	if ($rule eq '~~') {
		warn "#-Filters reset\n" if $Debug;
		reset_filters();
		return;
	}

	if ($rule =~ s/^~//) {	# tilde
		task_filter($rule, '-', '');
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

	my($func, $type) = map_filter_name($name);
	unless (defined $func) {
		warn "Warn unknown filter: $name\n";
		return;
	}

	warn "#-Filter $name\n" if $Debug;

	my($filter) = {
		func => $func,
		name => $name,
		type => $type,
		will => $will,
		dir => $dir,
	};

	push(@Rule_Filters, $filter);
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

sub Add_cct {
	my($value, $reason) = @_;

	print "Add_cct($value, $reason)\n" if $Debug;

	if ($value eq '*') {
		warn "#-Set *:              $reason\n" if $Debug;
		push(@CCT_Filters, [ '*', '*', $reason ]);
		return;
	}


	my($Category) = GTD::CCT->Use('Category');
	my($Context) = GTD::CCT->Use('Context');
	my($Timeframe) = GTD::CCT->Use('Timeframe');

	# match case sensative first
	if (defined $Category->get($value)) {
		warn "#-Set category:       $reason $value\n" if $Debug;
		push(@CCT_Filters, [ 'category', $value, $reason ]);
		return;
	}

	if ($Context->get($value)) {
		warn "#-Set space context:  $reason $value\n" if $Debug;
		push(@CCT_Filters, [ 'context', $value, $reason ]);
		return;
	}

	if (defined $Timeframe->get($value)) {
		warn "#-Set time context:   $reason $value\n" if $Debug;
		push(@CCT_Filters, [ 'timeframe', $value, $reason ]);
		return;
	}

	for my $key (GTD::CCT::keys('Tag')) {
		next unless $key eq $value;

		warn "#-Set tag:            $key\n" if $Debug;
		push(@CCT_Filters, [ 'tag', $value, $reason ]);
		return;
	}

	#--------------------------------
	# match case insensative next
	#--------------------------------

	for my $key ($Context->keys()) {
		next unless lc($key) eq lc($value);

		warn "#-Set Space context:  $key\n" if $Debug;
		push(@CCT_Filters, [ 'context', $key, $reason ]);
		return;
	}

	for my $key ($Category->keys()) {
		next unless lc($key) eq lc($value);

		warn "#-Set Category:       $key\n" if $Debug;
		push(@CCT_Filters, [ 'context', $key, $reason ]);
		return;
	}

	for my $key ($Timeframe->keys()) {
		next unless lc($key) eq lc($value);

		warn "#-Set Time context:   $key\n" if $Debug;
		push(@CCT_Filters, [ 'timeframe', $key, $reason ]);
		return;
	}

	for my $key (GTD::CCT::keys('Tag')) {
		next unless lc($key) eq lc($value);

		warn "#-Set Tag:            $key\n" if $Debug;
		push(@CCT_Filters, [ 'tag', $key, $reason ]);
		return;
	}

	warn "Unknown cct: $reason $value (ignored)\n";
}


#******************************************************************************
#******************************************************************************
#******************************************************************************
#******************************************************************************
#******************************************************************************
sub map_class_name {
	my($word) = @_;

	$word = lc($word); 

	if ($word eq 'any') {
		$Default_class = '%';
		return 1;

	} elsif ($word eq 'all') {
		$Default_class = '*';
		return 1;

	} elsif ($word eq 'list') {
		$Default_class = 'l';
		return 1;

	} elsif ($word eq 'hier') {
		$Default_class = 'h';
		return 1;

	} elsif ($word eq 'task') {
		$Default_class = 't';
		return 1;

	}
	return 0;
}

sub map_filter_name {
	my($word, $dir) = @_;

	my($level) = '*';
	if ($word =~ s/^([a-z])://) {
		$level = $1;
	}

	# ###BUG### filter_noop is a kludge
	return (\&filter_noop, $level) if map_class_name($word, $level);

	return (\&filter_done, $level)	if $word =~ /^done/i;
	return (\&filter_some, $level)	if $word =~ /^some/i;
	return (\&filter_some, $level)	if $word =~ /^maybe/i;

	return (\&filter_task, $level)	if $word =~ /^action/i;
#	return (\&filter_next, $level)	if $word =~ /^pure_next/i;
# we need to re-think this live-next vs next

	return (\&filter_next, $level)	if $word =~ /^next/i;
	return (\&filter_active, $level)	if $word =~ /^active/i;
	return (\&filter_live, $level)	if $word =~ /^live/i;
	return (\&filter_dead, $level)	if $word =~ /^dead/i;
	return (\&filter_idle, $level)	if $word =~ /^idle/i;

	return (\&filter_wait, $level)	if $word =~ /^wait/i;
	return (\&filter_wait, $level)	if $word =~ /^tickle/i;
	return (\&filter_late, $level)	if $word =~ /^late/i;
	return (\&filter_due,  $level)	if $word =~ /^due/i;

	return (\&filter_slow, $level)	if $word =~ /^slow/i;
	return (\&filter_idea, $level)	if $word =~ /^idea/i;

	return ();
}

# return + if wanted
# return - if unwanted
# return ? if unknown

sub filter_any {
	my($ref) = @_;

	my($arg) = $Default_class;

	return "+any"  if $arg eq '%';
	return "+all"  if $arg eq '*';
	return "+task" if $arg eq 't' && $ref->is_task();
	return "+hier" if $arg eq 'h' && $ref->is_hier();
	return "+list" if $arg eq 'l' && $ref->is_list();
	
	my($type) = $ref->get_type();

	return "+is:".$type if $arg == $type;

	return '';
}

sub filter_task {
	my($ref) = @_;

	return '' unless $ref->is_task();
	return '+task';
}

sub filter_done {
	my($ref) = @_;

	return '+done' if $ref->is_completed();
	return '';
}


sub filter_pure_next {
	my($ref) = @_;

	return '' unless $ref->is_task();
	return '+next' if $ref->get_nextaction() eq 'y';
	return '';
}


sub filter_tickle {
	my($ref) = @_;

	return '+tickle' if $ref->get_tickle();
	return '';
}

sub filter_wait {
	my($ref) = @_;

	my($type) = $ref->get_type();
	return '+wait' if $type eq 'w';
	return '';
}


sub filter_late {
	my($ref) = @_;

	my($due)  = $ref->get_due();
	return '' unless $due;

	if ($due le $Today) {
		return '+late'.$due;
	}
	return '';
}


sub filter_due {
	my($ref) = @_;

	my($due)  = $ref->get_due();
	return '' unless $due;

	if ($due ge $Today and $due le $Soon) {
		return '+due'.$due;
	}
	return '';
}


sub filter_slow {
	my($ref) = @_;

	my($pri) = $ref->get_priority();
	return '+slow' if $pri == 4;
	return '';
}


sub filter_idea {
	my($ref) = @_;

	my($pri) = $ref->get_priority();
	return '+idea' if $pri == 5;
	return '';
}


sub filter_some {
	my($ref) = @_;

	my($mask) = task_mask($ref);
	return '+some' if ($mask & T_MASK) == T_FUTURE;
	return '';
}

sub filter_next {
	my($ref) = @_;

	my($mask) = task_mask($ref);

	if ($ref->is_task()) {
		return '+live=n' if ($mask & T_MASK) == T_NEXT;
	} else {
		return filter_live($ref);
	}

	return '';
}

sub filter_active {
	my($ref) = @_;

#	return '' unless $ref->is_task();

	my($mask) = task_mask($ref);

	return '-act=d' if ($mask & A_MASK) == A_DONE;
	return '-act=s' if ($mask & A_MASK) == A_SOMEDAY;
	return '-act=t' if ($mask & A_MASK) == A_TICKLE;
	return '-act=w' if ($mask & A_MASK) == A_WAITING;

	if ($ref->is_task()) {
		return '+act=n' if ($mask & T_MASK) == T_NEXT;
		return '+act=a' if ($mask & T_MASK) == T_ACTIVE;
	}

	return '';
}

sub filter_live {
	my($ref) = @_;

#	return '' unless $ref->is_task();

	my($mask) = task_mask($ref);

	return '-live=d' if ($mask & A_MASK) == A_DONE;

	if ($ref->is_task()) {
		return '+live=n' if ($mask & T_MASK) == T_NEXT;
		return '+live=a' if ($mask & T_MASK) == T_ACTIVE;
		return '+live=f' if ($mask & T_MASK) == T_FUTURE;
	}

	return '';
}


sub filter_dead {
	my($ref) = @_;

	return '' unless $ref->is_task();

	my($mask) = task_mask($ref);
	return '+dead=d' if ($mask & T_MASK) == T_DONE;
	return '';
}



sub filter_noop {
	return '+all';
}

1;
