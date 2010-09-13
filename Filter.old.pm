package Hier::Filter;

use strict;
use warnings;

our $Version = 1.0;

use POSIX qw(strftime);
use Hier::util;
use Hier::Tasks;

my $Today = _today();
my $Soon  = _today(+7);

sub _today {
        my($later) = @_;
        $later = 0 unless $later;

        my($now) = time();
        my($when) = $now + 60*60*24 * $later; # 7 days

	return strftime("%04Y-%02m-%02d \%T", gmtime($when));
}

sub get_today {
	return $Today;
}


sub filtered {
	my ($ref) = @_;

	return 1 if cct_filtered($ref);

	return 1 if $ref->hier_filtered();
	return 1 if $ref->task_filtered();
	return 1 if $ref->list_filtered();

	return 0;
}

my($Include) = 0;	# types of actions to include
my($Exclude) = 0;	# types of actions to exclude
my($Walked) = 0;
my($Debug) = 0;

###======================================================================
###
###======================================================================
# todo_id:        1889				id/type
# type:           a			[ ]
# nextaction:     n			[_]
# isSomeday:      n			(_)

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

# owner:					palm info
# palm_id:
# private:
###======================================================================
###======================================================================
#
# task filters:
#
use constant {
	ATTRMASK	=> 0x0000_0F1F,	# attribute mask
	A_MASK		=> 0x0000_F080,	# action mask
	P_MASK		=> 0x00FF_0000,	# project mask

	TYPEMASK	=> 0x0F00_0000,	# type mask
	T_TASK		=> 0x0100_0000,	# object is some kind of action
	T_LIST		=> 0x0200_0000,	# object is some kind of list
	T_HIER		=> 0x0400_0000,	# object is some kind of parent

# done/next/current/later
	T_NEXT		=> 0x01,
	T_WAITING	=> 0x02,
	T_SOMEDAY	=> 0x04,	# someday/maybe
	T_TICKLE	=> 0x08,
	T_DONE		=> 0x10,

# timeframe hints
	T_LATE		=> 0x0100,	# priority == 1
					# or Due < today

	T_DUE           => 0x0200,	# priority == 2
					# or Due < week

	T_SLOW		=> 0x0400,	# priority == 4
	T_IDEA		=> 0x0800,	# priority == 5

# action states
	A_NEXT		=> 0x1000,
	A_ACTION	=> 0x2000,
	A_LATER		=> 0x4000,	# someday/maybe
	A_WAIT		=> 0x8000,	# someday/maybe
	A_DONE		=> 0x80,

# project hints
	P_PLAN		=> 0x01_0000,	# has no actions (needs plans)
	P_WAIT		=> 0x02_0000,	# only has waits
	P_ACTION	=> 0x04_0000,	# only has actions (no next)
	P_NEXT		=> 0x08_0000,	# has next actions
# topdown implies
	P_FUTURE	=> 0x10_0000,	# is someday/maybe/tickled
	P_DONE		=> 0x20_0000,	# is done
};

sub add_filter {
	my(@rules) = @_;

	unless ($Walked++) {
		$Debug = option('Debug');
		for my $ref (Hier::Tasks::matching_type('m')) {
			do_walk($ref);
		}
	}

	foreach my $rule (@rules) {
		print "#-Filter: $rule\n" if $Debug;

		if ($rule eq '~~') {
			$Include = $Exclude = 0;
			next;
		}
		$rule =~ s/^\~([+-~=])/$1/;

		if ($rule =~ s/^\=//) {
			$Exclude = 0;
			$Include = task_filter($rule);
			next;
		}
		if ($rule =~ s/^\-//) {
			$Include &= task_filter($rule, ~0);
			next;
		}
		if ($rule =~ s/^\+//) {
			$Include |= task_filter($rule);
			$Exclude &= ~task_filter($rule);
			next;
		}
		if ($rule =~ s/^\~//) {
			$Exclude |= task_filter($rule);
			next;
		}
	}
	print "#-Filter Sub: ", dispflags($Exclude), "\n" if $Debug;
	print "#-Filter Add: ", dispflags($Include), "\n" if $Debug;
}

sub dispflags {
	my($flags) = @_;

	#              0         1
	#              01234567890123456
	my($result) = '-----=';
	#              Dn swt odsi

	substr($result,  0, 1) = 'x' if $flags & T_DONE;
	substr($result,  1, 1) = 'n' if $flags & T_NEXT;
	substr($result,  2, 1) = 'w' if $flags & T_WAITING;
	substr($result,  3, 1) = 's' if $flags & T_SOMEDAY;
	substr($result,  4, 1) = 't' if $flags & T_TICKLE;

	$result .= 'T:' if $flags & T_TASK;
	$result .= 'H'  if $flags & T_HIER;
	$result .= 'L'  if $flags & T_LIST;

	$result .= 'n' if $flags & A_NEXT;
	$result .= 'a' if $flags & A_ACTION;
	$result .= 's' if $flags & A_LATER;
	$result .= 'x' if $flags & A_DONE;

	$result .= '=';

	$result .= 'P' if $flags & P_PLAN;
	$result .= 'W' if $flags & P_WAIT;
	$result .= 'A' if $flags & P_ACTION;
	$result .= 'N' if $flags & P_NEXT;
	$result .= 'F' if $flags & P_FUTURE;
	$result .= 'X' if $flags & P_DONE;

	$result .= ' <';

	$result .= '1' if $flags & T_LATE;
	$result .= '2' if $flags & T_DUE;
	$result .= '4' if $flags & T_SLOW;
	$result .= '5' if $flags & T_IDEA;

	$result .= '>';
	return $result;
}

sub task_filter {
	my($word, $rv) = @_;

	return T_DONE		if $word =~ /^t_done/i;
	return T_NEXT		if $word =~ /^t_next/i;
	return T_SOMEDAY	if $word =~ /^t_some/i;
	return T_WAITING	if $word =~ /^t_wait/i;
	return T_TICKLE		if $word =~ /^t_tickle/i;

	return T_LATE		if $word =~ /^late$/i;
	return T_DUE		if $word =~ /^due/i;
	return T_SLOW		if $word =~ /^slow/i;
	return T_IDEA		if $word =~ /^idea/i;

	return T_TASK		if $word =~ /^task/i;
	return T_LIST		if $word =~ /^list/i;
	return T_HIER		if $word =~ /^hier/i;

	return T_TASK|T_LIST|T_HIER
				if $word =~ /^any/i;

	return 0xFFFF		if $word =~ /^all/i;

	return A_ACTION		if $word =~ /^cur/i;
	return A_NEXT		if $word =~ /^next/i;
	return A_LATER		if $word =~ /^some/i;
	return A_LATER		if $word =~ /^maybe/i;
	return A_WAIT		if $word =~ /^wait/i;
	return A_DONE		if $word =~ /^done/i;

	return P_NEXT|P_ACTION|P_PLAN
	     | A_NEXT|A_ACTION	if $word =~ /^live/i;

	return A_LATER|A_WAIT|A_DONE|P_DONE	
	     | P_FUTURE|P_WAIT	if $word =~ /^dead/i;	# not live :-)

	return P_FUTURE|P_WAIT|A_WAIT|A_LATER
				if $word =~ /^later/i;	

	return P_DONE		if $word =~ /^complete/i;
	return P_ACTION		if $word =~ /^current/i;
	return P_NEXT	 	if $word =~ /^active/i;
	return P_FUTURE		if $word =~ /^future/i;
	return P_WAIT		if $word =~ /^hold/i;
	return P_PLAN		if $word =~ /^plan/i;

	print "Warn filter word: $word unknown\n";

	$rv = 0 unless defined $rv;
	return $rv;
}

sub task_mask {
	my ($ref) = @_;

	return $ref->{_mask} if defined $ref->{_mask};

	my($filter) = 0x0000;

	my($due)  = $ref->get_due();
	my($done) = $ref->get_completed();
	my($type) = $ref->get_type();

	$filter |= T_DONE	if $done;  # step on next/somday/tickle
	$filter |= T_NEXT	if $ref->get_nextaction() eq 'y';
	$filter |= T_SOMEDAY	if $ref->get_isSomeday() eq 'y';
	$filter |= T_TICKLE	if $ref->get_tickledate() gt $Today;
	$filter |= T_WAITING	if $type eq 'w';

	my($pri) = $ref->{priority} || 3;
	$filter |= T_LATE	if $pri == 1;
	$filter |= T_DUE	if $pri == 2;
	$filter |= T_SLOW	if $pri == 4;
	$filter |= T_IDEA	if $pri >= 5;

	if ($done) {
		$filter |= T_LATE	if $due && $due lt $done;
	}
	if ($due) {
		$filter |= T_LATE	if $due lt $Today;
		$filter |= T_DUE	if $due ge $Today and $due le $Soon;
	}

	$filter |= T_HIER	if $type =~ /[mvogp]/;
	$filter |= T_TASK	if $type =~ /[aiw]/;
	$filter |= T_LIST	if $type =~ /[rLCT]/;

	if ($filter & T_TASK) {
		my($some) = $filter & (T_SOMEDAY|T_TICKLE);
		my($next) = $filter & T_NEXT;
		my($wait) = $filter & T_WAITING;

		$filter |= 
			$done ? A_DONE   :
			$some ? A_LATER  :
			$wait ? A_WAIT   :
			$next ? A_NEXT   :
			        A_ACTION ;
	}

	$ref->{_mask} = $filter;

#	print "Filter: $ref->{todo_id} == ", dispflags($filter), "\n";
	return $filter;
}

sub task_mask_disp {
	my($ref) = @_;

	return dispflags($ref->task_mask());
}

sub task_filtered {
	my ($ref) = @_;

	my($mask) = $ref->task_mask();

        return 0 unless $ref->is_ref_task();

	return 1 if $mask & (A_MASK|TYPEMASK|ATTRMASK) & $Exclude;
	return 0 if $mask & (A_MASK|TYPEMASK|ATTRMASK) & $Include;

	return 1;
}

sub hier_filtered {
	my($ref) = @_;

	my($mask) = $ref->task_mask();
	
        return 0 unless $ref->is_ref_hier();

	return 1 if $mask & (P_MASK|TYPEMASK) & $Exclude;
	return 0 if $mask & (P_MASK|TYPEMASK) & $Include;

	return 1;
}

sub list_filtered {
	my($ref) = @_;

        return 0 unless $ref->is_ref_list();

	my($mask) = $ref->task_mask();

	return 1 if $mask & TYPEMASK & $Exclude;
	return 0 if $mask & TYPEMASK & $Include;

	return 1;
}

sub do_walk {
	my($ref) = @_;

	my($mask) = $ref->task_mask();

	if ($ref->is_ref_hier()) {
		if ($ref->get_completed()) {
			set_attribute($ref, P_DONE);
			return P_DONE;
		}
		if ($ref->get_isSomeday() eq 'y'
		or  $ref->get_tickledate()) {
			set_attribute($ref, P_FUTURE);
			return P_FUTURE;
		}

	}
	$ref->{_mask} |= find_attribute($ref);

	return $ref->{_mask} & P_MASK;
}

sub set_attribute {
	my($ref, $val) = @_;

	my($mask) = $ref->task_mask();
	return if $mask & P_MASK;	# sub-attributes done

	$ref->{_mask} |= $val;

	return unless $ref->is_ref_hier();

	for my $child ($ref->get_children()) {
		set_attribute($child, $val);
	}
	return;
}

sub find_attribute {
	my($ref) = @_;

	my($mask) = $ref->task_mask();	# sets low level masks;

	# we know the result.
	if ($mask & P_MASK) {
		return $mask & P_MASK;
	}

	# lists don't add to the attributes of projects
	if ($ref->is_ref_list()) {
		return 0;
	}
	if ($ref->is_ref_task()) {
		return 0	if $mask & A_DONE;	# ignore attr
		return P_NEXT   if $mask & A_NEXT;
		return P_FUTURE if $mask & A_LATER;
		return P_WAIT   if $mask & A_WAIT;
		return P_ACTION;
	}

	my($val) = 0;
	if ($ref->is_ref_hier()) {
		for my $child ($ref->get_children()) {
			$val |= do_walk($child);
		}
	}
	if ($val & P_NEXT) {
		return P_NEXT;
	}
	if ($val & P_ACTION) {
		return P_ACTION;
	}
	if ($val & P_WAIT) {
		return P_WAIT;
	}
	if ($val & P_FUTURE) {
		return P_FUTURE;
	}
	return P_PLAN;
}

1;
