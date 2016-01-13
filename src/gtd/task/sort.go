package task

//?	@EXPORT      = qw(sort_mode sort_tasks by_task by_goal by_goal_task )

import "sort"
import "strings"

var by_sort func(a, b *Task) bool = by_tid

func (slice Tasks)Len() int {
	return len(slice)
}

func (slice Tasks)Less(i, j int) bool {
	return by_sort(slice[i], slice[j])
}

func (slice Tasks)Swap(i, j int) {
    slice[i], slice[j] = slice[j], slice[i]
}

func (slice Tasks)Sort() Tasks {
	sort.Sort(slice)
	return slice
}

var sort_Criteria = map[string]func(*Task, *Task) bool {
	"id"	 : by_tid,
	"tid"	 : by_tid,
	"task"	 : by_task,
	"title"	 : by_task,

	"hier"	 : by_hier,

	"pri"	 : by_pri,
	"priority" : by_pri,
//	"panic"    : by_panic,
//	"focus"    : by_focus,

	"age"      : by_age,		// created date
	"date"     : by_age,		// ''

	"change"   : by_change,		// modified date

//	"doit"     : by_doitdate,
//	"doitdate" : by_doitdate,

//	"status"	 : by_status,

//	"rgpa"     : by_goal_task,
//	"goaltask" : by_goal_task,
}

//? my(%Meta_key, %Focus_key, %Panic_key)


func Sort_mode(mode string) {
/*?
	unless (defined $mode) {
		$Sorter = \&by_task
		return
	}

	$mode =~ s/^\^//;	// default is asending 
	if ($mode =~ s/^\~//) {	// desending
		option("Reverse", 1)
	}
	$mode = lc($mode)

	unless (defined $Criteria{$mode}) {
		warn "Unknown Sort mode: $mode\n"
		return
	}

	$Sorter = $Criteria{$mode}

	%Meta_key = ();		// clear any cached keys
?*/
}

/*?
sub sort_tasks {
	my($rev) = option("Reverse", 0)

	if ($rev) {
		return reverse sort { &$Sorter($a,$b) } @_
	}
	
	return sort { &$Sorter($a,$b) } @_
	//# comment out prev line to Debug.
	my(@list) =  sort { &$Sorter($a,$b) } @_

	for my $ref (@list) {
		my $tid = $ref->get_tid()
		my $title = lc_title($ref)

		my $key = $Meta_key{$tid} || ''
		print "$tid => $title\n"
	}
	return @list
}

my %Sort_cache
?*/

func by_tid(a, b *Task) bool {
	return a.Tid < b.Tid
}

func by_hier(a, b *Task) bool {
	pa := a.Parent()
	pb := b.Parent()

	switch {
	case pa != nil && pb != nil:
		if pa != pb {
			return by_hier(pa, pb)
		}

	case pa != nil:
		return true

	case pb != nil:
		return false
	}

	// no parents or parents equal
	return  lc_title(a) < lc_title(b) || 
		a.Tid < b.Tid
}

/*?
func by_status(a, b *Task) bool {
	my $ac = $a->get_completed()
	my $bc = $b->get_completed()

	if ($ac and $bc) {
		return $ac cmp $bc
	}

	return -1 if $ac;	// a completed but not b, sort early
	return  1 if $bc;	// b completed but not a, sort late

	return by_change($a, $b)
}
?*/

func by_change(a, b *Task) bool {
	return a.Modified < b.Modified
}

func by_age(a, b *Task) bool {
	return a.Created < b.Created
}

func by_Task(a, b *Task) bool {
	return by_task(a,b) || by_tid(a,b)
}

func by_task(a, b *Task) bool {
	return lc_title(a) < lc_title(b)
}

func by_pri(a, b *Task) bool {
	// order by priority $order, created $order, due $order 

	return a.Priority < b.Priority ||
		a.Created < b.Created ||
		a.Due < b.Due
}

/*?
func by_doitdate(a, b *Task) {
        return sort_doit($a) cmp sort_doit($b)
}

sub sort_doit {
	my($ref) = @_

	my($tid) = $ref->get_tid()
	return $Sort_cache{$tid} if defined $Sort_cache{$tid}

	my($v) = $ref->get_doit() || $ref->get_created()

	$Sort_cache{$tid} = $v
	return $v
}


func by_goal(a, b *Task) {
	my($a, $b) = @_
	return sort_goal($a) cmp sort_goal($b)
}

sub sort_goal {
	my($ref) = @_

	my($tid) = $ref->get_tid()

	return $Sort_cache{$tid} if defined $Sort_cache{$tid}

	my(@list)
	for (;;) {
		unshift(@list, lc_title($ref), $tid)
		last if $ref->get_type() eq 'g'
		$ref = $ref->get_parent
		last if !defined $ref
	}
	
	$Sort_cache{$tid} = join("\t", @list)

	return $Sort_cache{$tid}
}

sub by_goal_task($$) {
	my($a, $b) = @_

	return Meta_key($a) cmp Meta_key($b)
}

sub Meta_key {
	my($ref) = @_

	my($tid) = $ref->get_tid()

	my($val) = $Meta_key{$tid}
	return $val  if defined $val

	my($title) = lc_title($ref)

	my($p_title) = "--"
	my($g_title) = "--"
	my($p_ref) = $ref->get_parent()
	if ($p_ref) {
		$p_title = lc_title($p_ref)
		my($g_ref) = $p_ref->get_parent()
		if ($g_ref) {
			$g_title = lc_title($g_ref)
		}
	} 
	$val = "$g_title\t$p_title\t$title\t$tid",  
	$Meta_key{$tid} = $val
	return $val
}

// next   norm  some  done 
// 012345 12345 12345
//  abcde fghij klmno z

sub item_focus {
	my($ref) = @_

	my($pri) = $ref->get_priority()

	if ($ref->is_nextaction()) {
				// cool	1-5  == abcde
	} elsif ($ref->is_someday()) {
		$pri += 10;	// slow 11-15 == jklmn
	} else {
		$pri += 5;	// ok    6-10 == fghij
	}

	$pri = 1  if $pri < 1
	$pri = 15 if $pri > 15

	$pri = chr(ord('a') + $pri - 1)

	$pri = 'z' if $ref->is_completed()

	return $pri
}

sub calc_focus {
	my($ref) = @_

	unless (defined $ref) {
		return ''
	}

	my($tid) = $ref->get_tid()

	my($val) = $Focus_key{$tid}
	return $val  if defined $val

	my($pri) = item_focus($ref)

	$val = calc_focus($ref->get_parent()) . $pri
	$Focus_key{$tid} = $val

	return $val
}


sub by_focus($$) {
	my($a, $b) = @_

	return calc_focus($a) cmp calc_focus($b)
}

// next   norm  some  done 
// 012345 12345 12345
//  abcde fghij klmno z

sub calc_panic {
	my($ref) = @_

	unless (defined $ref) {
		return ''
	}

	my($tid) = $ref->get_tid()

	my($val) = $Panic_key{$tid}
	return $val if defined $val

	$val = item_focus($ref)
	for my $child ($ref->get_children()) {
		my $pri = calc_panic($child)
		$val = $pri if $pri lt $val
	}
	
	$Panic_key{$tid} = $val

	return $val
}



sub by_panic($$) {
	my($a, $b) = @_

	return (calc_panic($a) cmp calc_panic($b))
	    || by_hier($a, $b)
}

?*/

func lc_title(t *Task) string {
	title := strings.ToLower(t.Title)

//?	$title =~ s/\[\[//g
//?	$title =~ s/\]\]//g

	return title
}

