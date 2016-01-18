package task

import (
	"fmt"
	"log"
	"strconv"
	"strings"
)

// Done is used to signal shutdown.  Channel will close at exit
var Done chan *Task // task that need saving are written here
var Max_todo int    // Last todo id (unique for all tables)

type T_task byte

const (
	T_VISION      T_task = 'm'
	T_VALUE       T_task = 'v'
	T_ROLE        T_task = 'o'
	T_GOAL        T_task = 'g'
	T_PROJECT     T_task = 'p'
	T_SUB_PROJECT T_task = 's' // not a real type

	T_ACTION T_task = 'a'
	T_NEXT   T_task = 'n' // next action is not a real type
	T_INBOX  T_task = 'i'
	T_WAIT   T_task = 'w'

	T_REFERENCE T_task = 'r'
	T_ITEM      T_task = 'T'

	T_LIST      T_task = 'L'
	T_CHECKLIST T_task = 'C'
)

type Tasks []*Task

type Task struct {
	Tid   int
	Type  byte // should be T_task
	State byte

	Title       string
	Description string
	Note        string

	Category  string
	Context   string
	Timeframe string

	Doit       string // time.Time
	Due        string // time.Time
	Tickledate string // time.Time
	Completed  string // time.Time

	Priority int
	Effort   int
	Percent  int

	Resource string

	IsNextaction bool
	IsSomeday    bool
	Later        string // time.Time

	Created  string // time.Time
	Modified string // time.Time

	Recur string
	Rdesc string

	Hint []string
	Tags []string

	// Depends  Tasks
	Depends  string // we really need to upgrade this
	Parents  Tasks
	Children Tasks

	dirty    map[string]bool // used by db
	filtered string          // used by filter
	live     bool
	mask     uint
	level    int // used by walk
}

func (t *Task) String() string {
	return fmt.Sprintf("%c:%d", t.Type, t.Tid)
}

func (t *Task) Level() int {
	if t.level == 0 {
		p := t.Parent()
		if p == nil {
			t.level = 1
			return t.level
		}
		t.level = p.Level() + 1
		return t.level
	}
	return t.level
}

func init() {
	Done = make(chan *Task)

	go func() {
	loop:
		for {
			select {
			case task := <-Done:
				fmt.Printf("Done %d\n", task.Tid)
				if task.Dirty() {
					fmt.Printf("Dirty %d\n", task.Tid)
					// task.Save()
				}
			default:
				break loop
			}
		}

		clean_up_database()
	}()

}

func (t *Task) Dirty() bool {
	return t.dirty != nil
}

// all Todo items (including Hier)
var all_Tasks = map[int]*Task{}

// lookup up a task
func Find(tid int) *Task {
	if task, ok := all_Tasks[tid]; ok {
		return task
	}
	fmt.Printf("Can't find task id %d\n", tid)
	panic("find")
	return nil
}

func All() Tasks {
	v := make(Tasks, 0, len(all_Tasks))

	for _, value := range all_Tasks {
		v = append(v, value)
	}
	return v
}

func New(tid int) *Task {
	if tid > 0 && all_Tasks[tid] != nil {
		log.Fatal("Task %d exists won't create it.", tid)
	}
	var t Task

	if tid == 0 {
		if Max_todo == 0 {
			Max_todo = G_val("itemstatus", "max(itemId)")
		}
		Max_todo++
		tid = Max_todo
	} else {
		if Max_todo < tid {
			Max_todo = tid
		}
	}

	t.Tid = tid

	all_Tasks[tid] = &t // keep track of new task

	return &t
}

func (t *Task) Insert() {
	gtd_insert(t)
	t.dirty = nil
}

func Max() int {
	return Max_todo
}

//------------------------------------------------------------------------------
// Package Dirty
//
func (t *Task) Is_dirty() bool {
	return t.dirty != nil
}

func (t *Task) get_dirty(field string) bool {
	if t.dirty == nil {
		return false
	}

	return t.dirty[field]
}

func (t *Task) set_dirty(field string) *Task {
	if t.dirty == nil {
		t.dirty = make(map[string]bool)
	}
	t.dirty[field] = true

	Sort_invalidate_key(t)
	return t
}

func (t *Task) clean_dirty() *Task {
	t.dirty = nil
	return t
}

func (t *Task) Delete() {
	tid := t.Tid

	delete(all_Tasks, tid)

	// remove my children from self
	for _, child := range t.Parents {
		t.orphin_child(child)
	}

	// remove self from my parents
	for _, parent := range t.Parents {
		parent.orphin_child(t)
		parent.Update()
	}

	gtd_delete(tid) // remove from database
}

//------------------------------------------------------------------------------

/*?
sub default {
	my($val, $default) = @_

	return $default unless defined $val

	return '" if $val eq "0000-00-00'
	return '" if $val eq "0000-00-00 00:00:00'

	return $val
}
?*/

func (t *Task) Get_KEY(key string) string {
	switch key {
	case "tid", "todo_id":
		return fmt.Sprintf("%d", t.Tid)
	case "type":
		return fmt.Sprintf("%c", t.Type)

	case "nextaction":
		if t.IsNextaction {
			return "y"
		} else {
			return "n"
		}
	case "issomeday":
		if t.IsSomeday {
			return "y"
		} else {
			return "n"
		}

	case "title":
		return t.Title
	case "desc", "description":
		return t.Description
	case "note", "result":
		return t.Note

	case "category":
		return t.Category
	case "context":
		return t.Context
	case "timeframe":
		return t.Timeframe

	case "created":
		return t.Created
	case "modified":
		return t.Modified
	case "completed":
		return t.Completed

	case "doit":
		return t.Doit
	case "tickledate":
		return t.Tickledate
	case "due":
		return t.Due

	case "recur":
		return t.Recur
	case "recurdesc":
		return t.Rdesc

	case "resource":
		return t.Resource
	case "priority":
		return fmt.Sprintf("%d", t.Priority)
	case "state":
		return fmt.Sprintf("%c", t.State)
	case "effort":
		return fmt.Sprintf("%d", t.Effort)
	case "percent":
		return fmt.Sprintf("%d", t.Percent)
	case "depends":
		return t.Depends

	default:
		panic("Unknown key: " + key)
	}
}

/*?
sub get_KEY { my($self, $key) = @_;  return default($self->{$key}, ''); }

sub get_tid          { my($self) = @_; return $self->{todo_id}; }

sub get_category     { my($self) = @_; return default($self->{category}, ''); }
sub get_completed    { my($self) = @_; return default($self->{completed}, ''); }
sub get_context      { my($self) = @_; return default($self->{context}, ''); }
sub get_created      { my($self) = @_; return default($self->{created}, ''); }
sub get_depends      { my($self) = @_; return default($self->{depends}, ''); }
sub get_description  { my($self) = @_; return default($self->{description}, ''); }
sub get_doit         { my($self) = @_; return default($self->{doit}, ''); }
sub get_due          { my($self) = @_; return default($self->{due}, ''); }
sub get_effort       { my($self) = @_; return default($self->{effort}, ''); }
sub get_isSomeday    { my($self) = @_; return default($self->{isSomeday}, 'n'); }
sub get_later        { my($self) = @_; return default($self->{later}, ''); }
sub get_live         { my($self) = @_; return default($self->{live}, 1); }
sub get_mask         { my($self) = @_; return default($self->{mask}, undef); }
sub get_modified     { my($self) = @_; return default($self->{modified}, ''); }
sub get_nextaction   { my($self) = @_; return default($self->{nextaction}, 'n'); }
sub get_note         { my($self) = @_; return default($self->{note}, ''); }
sub get_priority     { my($self) = @_; return default($self->{priority}, 4); }
sub get_title        { my($self) = @_; return default($self->{task}, ''); }
sub get_tickledate   { my($self) = @_; return default($self->{tickledate}, ''); }
sub get_timeframe    { my($self) = @_; return default($self->{timeframe}, ''); }
sub get_todo_only    { my($self) = @_; return default($self->{_todo_only}, 0); }
sub get_type         { my($self) = @_; return default($self->{type}, '?'); }

sub get_resource     { my($self) = @_; return default($self->{resource}, ''); }
sub get_hint         { my($self) = @_; return default($self->{_hint}, ''); }

sub get_focus { return Hier::Sort::calc_focus(@_)}
sub get_panic { return Hier::Sort::calc_panic(@_)}
?*/

func (t *Task) Set_category(v string)     { t.Set_KEY("category", v) }
func (t *Task) Set_completed(v string)    { t.Set_KEY("completed", v) }
func (t *Task) Set_context(v string)      { t.Set_KEY("context", v) }
func (t *Task) Set_created(v string)      { t.Set_KEY("created", v) }
func (t *Task) Set_depends(v string)      { t.Set_KEY("depends", v) }
func (t *Task) Set_description(v string)  { t.Set_KEY("description", v) }
func (t *Task) Set_doit(v string)         { t.Set_KEY("doit", v) }
func (t *Task) Set_due(v string)          { t.Set_KEY("due", v) }
func (t *Task) Set_effort(v string)       { t.Set_KEY("effort", v) }
func (t *Task) Set_state(v string)        { t.Set_KEY("state", v) }
func (t *Task) Set_gtd_modified(v string) { t.Set_KEY("gtd_modified", v) }
func (t *Task) Set_isSomeday(v string)    { t.Set_KEY("isSomeday", v) }
func (t *Task) Set_later(v string)        { t.Set_KEY("later", v) }
func (t *Task) Set_live(v string)         { t.Set_KEY("live", v) }
func (t *Task) Set_mask(v string)         { t.Set_KEY("mask", v) }
func (t *Task) Set_modified(v string)     { t.Set_KEY("modified", v) }
func (t *Task) Set_nextaction(v string)   { t.Set_KEY("nextaction", v) }
func (t *Task) Set_note(v string)         { t.Set_KEY("note", v) }
func (t *Task) Set_priority(v string)     { t.Set_KEY("priority", v) }
func (t *Task) Set_title(v string)        { t.Set_KEY("task", v) }
func (t *Task) Set_tickledate(v string)   { t.Set_KEY("tickledate", v) }
func (t *Task) Set_timeframe(v string)    { t.Set_KEY("timeframe", v) }
func (t *Task) Set_todo_only(v string)    { t.Set_KEY("_todo_only", v) }
func (t *Task) Set_type(v string)         { t.Set_KEY("type", v) }
func (t *Task) Set_resource(v string)     { t.Set_KEY("resource", v) }
func (t *Task) Set_hint(v string)         { t.Set_KEY("_hint", v) }

/*?
sub hint_resource    {return clean_set("resource", @_); }

sub set_tid          {
	my($ref, $new) = @_

	my $tid = $ref->get_tid()

	if (defined $Task{$new}) {
		panic("Can't renumber tid $tid => $new (already exists)")
	}

	if ($ref->is_dirty()) {
		// make sure the rest of the object is clean
		$ref->update()
	}

	Hier::Db::G_renumber($ref, $tid, $new)

        $Task{$new} = $Task{$tid}
        delete $Task{$tid}
}

sub clean_set {
	my($field, $ref, $val) = @_

	unless (defined $val) {
		panic("Won't set $field to undef")
	}


	$ref->{$field} = $val
	return $ref
}

sub get_tags {
        my ($ref) = @_

        my $hash = $ref->{_tags}


        return sort {$a cmp $b} keys %$hash
}
?*/

func (t *Task) Disp_tags() string {
	return strings.Join(t.Tags, ", ")
}

/*?
sub set_tags {
	my($self) = shift @_

	$self->{_tags} = {}

	foreach my $tag (@_) {
		$self->{_tags}{$tag}++
	}
	return $self
}

?*/

// Set_KEY -- access field indirectly by name
func (t *Task) Set_KEY(key string, val string) {
	//	my($warn_val) = $val || ''
	//	if option.Debug("tasks") {
	//		warn "Dirty $field => $warn_val\n"
	//	}

	var err error = nil

	switch key {
	case "tid", "todo_id":
		// t.Tid = strconv.Atoi(val)
		panic("set_KEY(tid) not allowd")
	case "type":
		t.Type = val[0]
	case "title":
		t.Title = val
	case "parents":
		t.set_parent_ids(val)

	case "modified":
		t.Modified = val
	case "created":
		t.Created = val
	case "completed":
		t.Completed = val
	case "category":
		t.Category = val
		panic(".... code category update")

	case "issomeday":
		t.IsSomeday, err = strconv.ParseBool(val)
	case "context":
		t.Context = val
		panic(".... code context update")
	case "timeframe":
		t.Timeframe = val
		panic(".... code timeframe update")
	case "due":
		t.Due = val
	case "doit":
		t.Doit = val
	case "nextaction":
		t.IsNextaction, err = strconv.ParseBool(val)
	case "tickledate":
		t.Tickledate = val

	case "Parents":
		log.Printf(".... code set_KEY parents")
		//? t.Set_parent_ids(val)
		return
	case "Children":
		log.Printf(".... code set_KEY children")
		//? t.Set_children_ids(val)
		return
	case "Tags":
		//##BUG### tag setting not done yet
		log.Printf(".... code set_KEY tags")

	default:
		panic("task.Set_KEY: Unknown key " + key)
	}

	if err != nil {
		panic("Conversion error for " + key + ": " + val)
	}

	t.set_dirty(key)
}

func (self *Task) Update() {
	gtd_update(self)
	self.dirty = nil
}

func clean_up_database() {
	// show what should have been updated.
	//***BUG***	option.Set_debug("tasks")

	for tid, ref := range All() {
		if !ref.Is_dirty() {
			continue
		}

		fmt.Printf("Dirty: %s\n", tid)
		ref.Update()
	}
}

/*
func reload_if_needed_database() {
	my($changed) = option("Changed")
	my($cur) = Hier::Db::G_val("itemstatus", 'max(lastModified)')

	if ($cur ne $changed) {
		print "Database changed from $changed => $cur\n"
		//##BUG### reload database
		set_option("Changed", $cur)
	}
}

func init {
	go func() {
		<-Done
		clean_up_database()
	}()
}


sub is_later {
	my($ref) = @_

	my($tickle) = $ref->get_tickledate()

	return 0 unless $tickle
	return 0 if $tickle lt get_today();	// tickle is after today

	return 1
}

?*/
func (t *Task) Is_someday() bool {
	if t.Is_later() {
		return true
	}

	return t.IsSomeday
}

/*?
sub is_active {
	my($ref) = @_

	return 0 if $ref->is_someday()
	return 0 if $ref->get_completed()

	return 1
}
?*/

func (t *Task) Is_completed() bool {
	return t.Completed != ""
}

func (t *Task) Is_later() bool {
	//? what is later? see above
	return false
}

func (t *Task) Is_nextaction() bool {

	//?	return 0 if $ref->is_someday()
	//?	return 0 if $ref->get_completed()
	//?	return 1 if $ref->get_nextaction() eq 'y'

	return t.IsNextaction
}

/*?
// used by Hier::Walk to track depth of the current walk
sub set_level {
	my($self, $level) = @_

	panic("set_level missing level value") unless defined $level

	// now remember our level
	$self->{_level} = $level
}

sub level {
	my($self) = @_

	my($level) = $self->{_level}

	// we have alread defined it, return it.
	return $level if defined $level
	panic("level not set correctly?")
}

sub get_state {
	my($self) = @_

	my($state) = default($self->{state}, '-')

	if ($self->get_type() eq 'w') {
		if ($state != 'w') {
			$self->set_state('w')
			$state = 'w'
		}
	}

	return $state
}

*/
