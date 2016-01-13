package task

import	"io"
import	"log"

//?  @EXPORT      = qw(&walk &detail)

var	walk_Debug bool 

type Walk struct {
	Pre	func(*Walk, *Task)
	Detail	func(*Walk, *Task)
	Done	func(*Walk, *Task)

	seen	map[*Task]bool

	Depth	int

	fd	*io.Writer
}

// task.NewWalk creates a new toplevel walk structure
func NewWalk() *Walk {
	w := Walk{}

	w.Detail = show_detail
	w.Done   = end_detail
	w.Pre    = pre_detail


panic("... code NewWalk type_depth")
//?	w.fd = os.Stdout
//?	w.depth = type_depth('p');
	w.seen = make(map[*Task]bool)

	return &w
}

func (self *Walk) SetDetail(detail func()) {
}

func (self *Walk) SetDone(detail func()) {
}

func (self *Walk) SetPre(detail func()) {
}

func (w *Walk)walk() {
	panic("... code walk.Walk")
/*?
	my($toptype) = @_

	$toptype ||= 'm'

	if ($toptype =~ /^\d+/) {
		my($ref) = Find($toptype)
		if ($ref) {
			if ($ref->get_type() eq 'm') {
				$ref->set_level(1)
			} else {
				$ref->set_level(2)
			}
			$walk->{pre}->($walk, $ref)
			$walk->detail($ref)
		} else {
			warn "No such task: $toptype\n"
		}
		return
	}

	my(@top) = meta_matching_type($toptype)

	for my $ref (sort_tasks @top) {
		$ref->set_level(1)
		$walk->{pre}->($walk, $ref)
	}

	for my $ref (sort_tasks @top) {
		next if $ref->filtered()

		$ref->set_level(1)
		$walk->detail($ref)
	}
?*/
	return
}


func (w *Walk) set_depth(kind byte) {
	panic("... walk.set_depth  -- code set_depth")
//?	w.Depth = type_depth(kind)
}


func Filter(w *Walk) {
	panic("... code walk.Filter")
/*?
	my($tid, $kind)
	foreach my $ref (Hier::Tasks::all()) {
		$tid = $ref->get_tid
		$walk->{want}{$tid} = 1
		$walk->{want}{$tid} = 0 if $ref->filtered()
	}
	return

	for 
	foreach my $ref (Hier::Tasks::all()) {
		tid := t.Tid
		kind := t.Kind

		if kind == 'p' {
			next if $ref->filtered()

			$walk->{want}{$tid}++
			$walk->_want($ref->get_parents())
			next
		}

		if (kind == 'a' or kind == 'w') {
			next if $ref->filtered()

			$walk->{want}{$tid}++
			$walk->_want($ref->get_parents())
			next
		}
	}
?*/
}

/*?
// used by filter to walk up the tree add "want"edness to each parent.
sub _want {
	my($walk) = shift @_

	my($pid)
	foreach my $ref (@_) {
		$pid = $ref->get_tid()
		next if $walk->{want}{$pid}++

		$walk->_want($ref->get_parents())
	}
}
?*/

func detail(w *Walk, t *Task) {
	panic("... code walk.detail")
/*?
	my($sid, $name, $cnt, $desc, $pri, $done)

	my $level = $ref->level()
	my $depth = $walk->{depth}

	my $tid  = $ref->get_tid()
	my $kind = $ref->get_type()

	warn "detail($tid:$kind level:$level of $depth\n" if $Debug

	return if $walk->{seen}{$tid}++

	return if $ref->is_list()

	if ($walk->{want}{$tid} == 0) {
		// we are global filtered
		warn "< detail($tid) filtered\n" if $Debug
		return
	}

	unless ($kind) {
		//***BUG*** fixed: type was not set by new
		confess "$tid: bad type "$kind\n"; 
		return
	}
	if (type_depth($kind) > $depth) {
		warn "+ detail($tid)\n" if $Debug
		return
	}

	$walk->{detail}->($walk, $ref)

	foreach my $child (sort_tasks $ref->get_children()) {
		my $cid = $child->get_tid()
		warn "$tid => detail($cid)\n" if $Debug

		$child->set_level($level+1)
		$walk->detail($child)
	}

	$walk->{done}->($walk, $ref)
?*/
}

func show_detail(w *Walk, t *Task) {
	if !walk_Debug {
		return
	}

	log.Printf("### Hier::Walk::show_detail(%d)\n", t.Tid)
}

func end_detail(w *Walk, t *Task) {
	if !walk_Debug {
		return
	}

	log.Printf("### Hier::Walk::end_detail(%d)\n", t.Tid)
}

func pre_detail(w *Walk, t *Task) {
	if !walk_Debug {
		return
	}

	log.Printf("### Hier::Walk::pre_detail(%d)\n", t.Tid)
}
