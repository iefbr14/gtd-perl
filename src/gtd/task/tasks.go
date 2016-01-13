package task

import (
	"fmt"
	"log"
)

// Done is used to signal shutdown.  Channel will close at exit
var Done chan *Task // task that need saving are written here
var Max_todo int    // Last todo id (unique for all tables)

type T_task byte

const (
	T_VISION	T_task = 'm'
	T_VALUE		T_task = 'v'

	T_ROLE		T_task = 'o'
	T_GOAL		T_task = 'g'
	T_PROJECT	T_task = 'p'
	T_SUB_PROJECT	T_task = 's'	// not a real type

	T_ACTION	T_task = 'a'
	T_NEXT		T_task = 'n'	// next action

	T_INBOX		T_task = 'i'
	T_WAIT		T_task = 'w'

	T_REFERENCE	T_task = 'r'
	T_ITEM		T_task = 'T'

	T_LIST		T_task = 'L'
	T_CHECKLIST	T_task = 'C'
)

type Tasks []*Task

type Task struct {
	Tid      int
	Type 	 byte
	State 	 byte

	Title       string
	Description string
	Note        string

	Category    string
	Context     string
	Timeframe   string

	Doit        string	// time.Time
	Due         string	// time.Time
	Tickledate  string	// time.Time
	Completed   string	// time.Time

	Priority    int
	Effort      int
	Percent     int

	Resource    string

	IsNextaction bool
	IsSomeday    bool
	Later        string	// time.Time

	Created    string	// time.Time
	Modified   string	// time.Time

	Recur    string
	Rdesc    string

	Hint     []string
	Tags	 []string

	Depends     Tasks
	Parents     Tasks
        Children    Tasks

	dirty      map[string]bool	// used by db
	filtered   string		// used by filter
	live       bool
	mask       uint
	level	   int			// used by walk
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

func (ref *Task) Dirty() bool {
	return ref.dirty != nil
}

// all Todo items (including Hier)
var all_Tasks = map[int]*Task {}

// lookup up a task
func Find(tid int) *Task {
	if task, ok := all_Tasks[tid]; ok {
		return task
	}
	fmt.Printf("Can't find task id %d\n", tid)
	panic("find");
	return nil
}

func All() Tasks {
	v := make(Tasks, 0, len(all_Tasks))

	for _, value := range all_Tasks {
		v = append(v, value);
	}
	return v
}

func New(tid int) *Task {
	if tid > 0 && all_Tasks[tid] != nil {
		log.Fatal("Task %d exists won't create it.", tid)
	}
	var self Task

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

	self.Tid = tid

	all_Tasks[tid] = &self // keep track of new task

	return &self
}

func (self *Task) Insert() {
	gtd_insert(self)
	self.dirty = nil
}

func Max() int {
	return Max_todo
}


//------------------------------------------------------------------------------
// Package Dirty
//
func (self *Task) Is_dirty() bool {
	return self.dirty != nil
}

func (self *Task)get_dirty(field string) bool {
	if self.dirty == nil {
		return false
	}
	
	return self.dirty[field]
}

func (self *Task) set_dirty(field string) *Task {
	if self.dirty == nil {
		self.dirty = make(map[string]bool)
	}
	self.dirty[field] = true
	return self
}

func (self *Task) clean_dirty() *Task {
	self.dirty = nil
	return self
}

func (self *Task) Delete()  {
	tid := self.Tid

	delete(all_Tasks, tid)

	// remove my children from self
	for _,child := range self.Parents {
		self.orphin_child(child)
	}

	// remove self from my parents
	for _,parent := range self.Parents {
		parent.orphin_child(self)
		parent.Update()
	}

	gtd_delete(tid);	// remove from database
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

func (self *Task)get_KEY(key string) string {
	switch key {
	case "tid": return fmt.Sprintf("%d", self.Tid)
	case "type": return fmt.Sprintf("%c", self.Type)
	
	case "title": return self.Title

	"todo_id"       => "itemId")
	"modified"      => "lastModified")
	"created"       => "dateCreated")
	"completed"     => "dateCompleted")
	"type"          => "type")
	"_gtd_category" => "categoryId")

	"isSomeday"     => "isSomeday")
	"_gtd_context"  => "contextId")
	"_gtd_timeframe"=> "timeframeId")
	"due"           => "deadline")
	"nextaction"    => "nextaction")
	"tickledate"    => "tickledate")
	default: panic("Unknown key %s key", key)
	}
}

func (self *Task)set_KEY(key string, val string) {
	switch key {
	case "tid":   panic(set_KEY(tid) // self.Tid = strconv.Atoi(val)
	case "type":  self.Type = val[0]
	case "title": self.Title = val
	case "parents": self.set_parent_ids(val)
	default:
		
	}
	panic("Unknown key %s key", key)
}


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

sub set_category     {return dset("category", @_); }
sub set_completed    {return dset("completed", @_); }
sub set_context      {return dset("context", @_); }
sub set_created      {return dset("created", @_); }
sub set_depends      {return dset("depends", @_); }
sub set_description  {return dset("description", @_); }
sub set_doit         {return dset("doit", @_); }
sub set_due          {return dset("due", @_); }
sub set_effort       {return dset("effort", @_); }
sub set_state        {return dset("state", @_); }
sub set_gtd_modified {return dset("gtd_modified", @_); }
sub set_isSomeday    {return dset("isSomeday", @_); }
sub set_later        {return dset("later", @_); }
sub set_live         {return dset("live", @_); }
sub set_mask         {return dset("mask", @_); }
sub set_modified     {return dset("modified", @_); }
sub set_nextaction   {return dset("nextaction", @_); }
sub set_note         {return dset("note", @_); }
sub set_priority     {return dset("priority", @_); }
sub set_title        {return dset("task", @_); }
sub set_tickledate   {return dset("tickledate", @_); }
sub set_timeframe    {return dset("timeframe", @_); }
sub set_todo_only    {return dset("_todo_only", @_); }
sub set_type         {return dset("type", @_); }

sub set_resource     {return dset("resource", @_); }
sub set_hint         {return dset("_hint", @_); }
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
sub disp_tags {
        my ($ref) = @_

        return join(',', $ref->get_tags())
}
sub set_tags {
	my($self) = shift @_

	$self->{_tags} = {}

	foreach my $tag (@_) {
		$self->{_tags}{$tag}++
	}
	return $self
}

//
// dirty set
//
sub set_KEY { my($self, $key, $val) = @_;  return dset($key, $self, $val); }
sub dset {
	my($field, $ref, $val) = @_

	if ($field eq "Parents") {
		$ref->set_parent_ids($val)
		return
	}
	if ($field eq "Children") {
		$ref->set_children_ids($val)
		return
	}
	if ($field eq "Tags") {
		//##BUG### tag setting not done yet
		panic("Can't set tags yet")
	}


//	unless (defined $val) {
//		panic("Won't set $field to undef\n")
//	}

	// skip setting if already set that way!
	return $ref if defined($ref->{$field}) && defined($val)
		    && $ref->{$field} eq $val

	$ref->{$field} = $val

	return $ref if ($field eq "_hint"); # don't drop into dirty

	$ref->{_dirty}{$field}++

	my($warn_val) = $val || ''
	if option.Debug("tasks") {
		warn "Dirty $field => $warn_val\n"
	}

	return $ref
}

*/

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

	return t.IsSomeday;
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
