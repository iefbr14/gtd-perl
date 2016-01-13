package task

import	"log"

//?  @EXPORT      = qw(&walk &detail)

var	walk_Debug bool 

type Walk struct {
	Pre	func(*Walk, *Task)
	Detail	func(*Walk, *Task)
	Done	func(*Walk, *Task)

	seen	map[*Task]bool
	want	map[*Task]bool

	Depth	int
}

// task.NewWalk creates a new toplevel walk structure
func NewWalk() *Walk {
	w := Walk{}

	w.Detail = show_detail
	w.Done   = end_detail
	w.Pre    = pre_detail

	w.Depth = Type_depth('p');
	
	w.seen = make(map[*Task]bool)
	w.want = make(map[*Task]bool)

	return &w
}

func (w *Walk)Walk(tasks Tasks) {
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
	w.Depth = Type_depth(kind)
}


func (w *Walk)Filter() {
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

	level := t.level
	depth := w.Depth

	tid  := t.Tid
	kind := t.Type

	if walk_Debug {
		log.Printf("detail(%d:%c level:%d of %d\n",
			tid, kind, level, depth)
	}

	if w.seen[t] {
		return
	}
	w.seen[t] = true

	if t.Is_list() {
		return
	}

	if ! w.want[t] {
		// we are global filtered
		if walk_Debug {
			log.Printf("< detail(%d) filtered\n", tid)
		}
		return
	}

	if kind == 0 {
		log.Printf("bad kind %c for %d\n", kind, tid);
		return
	}

	if (Type_depth(kind) > depth) {
		if walk_Debug {
			log.Printf("+ detail(%d)\n", tid)
		}
		return
	}

	w.Detail(w, t)

	for _, child := range t.Children.Sort() {
		if walk_Debug {
			log.Printf("%d => detail(%d)\n", t.Tid, child.Tid)
		}
		child.level = level+1
		detail(w, child)
	}

	w.Done(w, t);
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
