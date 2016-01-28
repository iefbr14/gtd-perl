package task

import (
	"fmt"
	"log"
	"strconv"
	"strings"
)

import "gtd/option"

var task_Debug = false
var _ = option.DebugVar("task", &task_Debug)

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
	hint     string // resource hint

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

// Find - map tid to task return nil if it doesn't exist
func Find(tid int) *Task {
	if task, ok := all_Tasks[tid]; ok {
		return task
	}
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
		log.Printf("Task %d exists won't create it.", tid)
		return nil
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
		t.Orphin_child(child)
	}

	// remove self from my parents
	for _, parent := range t.Parents {
		parent.Orphin_child(t)
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

	case "doit":
		return t.Doit
	case "tickledate":
		return t.Tickledate
	case "due":
		return t.Due
	case "completed":
		return t.Completed

	case "recur":
		return t.Recur
	case "recurdesc":
		return t.Rdesc

	case "resource":
		return t.Resource
	case "priority":
		return fmt.Sprintf("%d", t.Priority)
	case "state":
		if t.State == 0 {
			return "-"
		}
		return fmt.Sprintf("%c", t.State)
	case "effort":
		return fmt.Sprintf("%d", t.Effort)
	case "percent":
		return fmt.Sprintf("%d", t.Percent)
	case "depends":
		return t.Depends

	case "parents", "Parents":
		return t.Disp_parents()

	case "children", "Children":
		return t.Disp_children()

	case "tags", "Tags":
		return t.Disp_tags()

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
func (t *Task) Set_gtd_modified(v string) { t.Set_KEY("gtd_modified", v) }
func (t *Task) Set_isSomeday(v string)    { t.Set_KEY("isSomeday", v) }
func (t *Task) Set_later(v string)        { t.Set_KEY("later", v) }
func (t *Task) Set_live(v string)         { t.Set_KEY("live", v) }
func (t *Task) Set_mask(v string)         { t.Set_KEY("mask", v) }
func (t *Task) Set_modified(v string)     { t.Set_KEY("modified", v) }
func (t *Task) Set_nextaction(v string)   { t.Set_KEY("nextaction", v) }
func (t *Task) Set_note(v string)         { t.Set_KEY("note", v) }
func (t *Task) Set_title(v string)        { t.Set_KEY("task", v) }
func (t *Task) Set_tickledate(v string)   { t.Set_KEY("tickledate", v) }
func (t *Task) Set_timeframe(v string)    { t.Set_KEY("timeframe", v) }
func (t *Task) Set_todo_only(v string)    { t.Set_KEY("_todo_only", v) }
func (t *Task) Set_type(v string)         { t.Set_KEY("type", v) }
func (t *Task) Set_resource(v string)     { t.Set_KEY("resource", v) }
func (t *Task) Set_hint(v string)         { t.Set_KEY("_hint", v) }

func (t *Task) Set_state(v byte) {
	t.State = v
	t.dirty["state"] = true
}

func (t *Task) Set_priority(v int) {
	t.Priority = v
	t.dirty["priority"] = true
}

/*?
sub hint_resource    {return clean_set("resource", @_); }
?*/

func (t *Task) Set_tid(new int) {
	tid := t.Tid

	if _, ok := all_Tasks[new]; ok {
		panic("Can't renumber tid $tid => $new (already exists)")
	}

	if t.Is_dirty() {
		// make sure the rest of the object is clean
		t.Update()
	}

	G_renumber(t, tid, new)

	all_Tasks[new] = all_Tasks[tid]
	delete(all_Tasks, tid)
}

func (t *Task) Set_effort(v int) {
	t.Effort = v
	t.set_dirty("effort")
}

/*?
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

	case "nextaction":
		t.IsNextaction, err = strconv.ParseBool(val)
	case "issomeday":
		t.IsSomeday, err = strconv.ParseBool(val)

	case "title":
		t.Title = val
	case "purpose", "description", "desc":
		t.Description = val
	case "outcome", "note", "result":
		t.Note = val

	case "category":
		t.Category = val
	case "context":
		t.Context = val
	case "timeframe":
		t.Timeframe = val

	case "created":
		t.Created = val
	case "modified":
		t.Modified = val

	case "doit":
		t.Doit = val
	case "tickledate":
		t.Tickledate = val
	case "due":
		t.Due = val
	case "completed":
		t.Completed = val

	case "recur":
		t.Recur = val
	case "recurdesc":
		t.Rdesc = val

	case "resource":
		t.Resource = val
	case "priority":
		t.Priority, err = strconv.Atoi(val)
	case "state":
		t.State = val[0]

	case "effort":
		t.Effort, err = strconv.Atoi(val)
	case "percent":
		t.Percent, err = strconv.Atoi(val)
	case "depends":
		t.Depends = val

	case "parents", "Parents":
		t.set_parent_ids(val)
		return
	case "children", "Children":
		log.Printf(".... code set_KEY children")
		//? t.Set_children_ids(val)
		return
	case "tags", "Tags":
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

func (t *Task) Update() {
	if t.dirty == nil {
		return
	}

	gtd_update(t)
	t.dirty = nil
}

func clean_up_database() {
	// show what should have been updated.
	//***BUG***	option.Set_debug("tasks")

	for tid, ref := range All() {
		if !ref.Is_dirty() {
			continue
		}

		fmt.Printf("Dirty: %d\n", tid)
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

// used by Hier::Walk to track depth of the current walk
func (t *Task) Set_level(level int) {
	t.level = level
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

/*?
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
