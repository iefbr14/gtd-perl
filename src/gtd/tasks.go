package gtd

// Done is used to signal shutdown.  Chanel will close at exit
var Done := make(<-chan);

type Task struct {
	Tid          int;
	Tasktype     char;

	Category     string;
	Completed    date;
	Context      string;
	Created      date;
	Depends      []int;
	Description  string;
	Doit         date;
	Due          date;
	Effort       duration;
	IsSomeday    bool;
	Later        date;

	live         bool;
	mask         uint;
	Modified     date;
	Nextaction   bool;

	Note         string;
	Priority     int;
	Title        string;
	Tickledate   date;
	Timeframe    []date;
	todo_only    bool;

	Resource     []string;
	Hint         []string;

	dirty		map[string]bool;
}

// all Todo items (including Hier)
var Tasks map[int]*Task;		

func Find(tid string)*Task  {
	return Find(stringconv.ParseInt(tid))
}

func Find(int) *Task {
	return Task[tid]
}

func All() []Task {
	v := make([]*Task, len(Tasks));
  idx := 0
    for  _, value := range m {
       v[idx] = value
       idx++
    }
	return v
}


Max_todo := 0; 	// Last todo id (unique for all tables)

func New(tid int) {
	if tid > 0 && Tasks[tid] != nil {
		panic("Task $tid exists won't create it.")
	}
	self := make(Task);

	if tid == 0 {
		if (Max_todo == 0 {
			Max_todo = Hier::Db::G_val("todo", 'max(todo_id)')
		}
		tid = ++Max_todo;
	} else {
		if Max_todo < $tid {
			Max_todo = tid 
		}
	}


	self.todo_id = tid

	Tasks[tid] = self	// keep track of new task

	return &self;
}

func Insert(self *Task) {
	my($self) = @_;

	Hier::Db::gtd_insert(self);
	self.dirty = nil
}

func Max() int {
	return Max_todo;
}


//------------------------------------------------------------------------------
// Package Dirty
//
func (self *Task) is_dirty() bool {
	return self.dirty != nil;
}

sub get_dirty {
	my($self,$field) = @_;

	return 0 unless defined $self->{_dirty};
	return defined $self->{_dirty}{$field};
}

func (self *Task) set_dirty(field string) *Task {

	self.dirty[field] = true;
	return self;
}

func (self *Task) clean_dirty() *Task {

	self.dirty = nil
	return self;
}

func (self *Task) delete  {

	my $tid = $self->{todo_id};
	delete $Task{$tid};

	// remove my children from self
	for my $child ($self->get_parents) {
		$self->orphin_child($child);
	}
	$self->update();

	// remove self from my parents
	for my $parent ($self->get_parents) {
		$parent->orphin_child($self);
		$parent->update();
	}


	// commit suicide
	Hier::Db::sac_delete($tid);
	Hier::Db::gtd_delete($tid);	// remove from database

	//##BUG### need to reflect back database changed.
	//##G_sql("update");
	return;
}

//------------------------------------------------------------------------------

sub default {
	my($val, $default) = @_;

	return $default unless defined $val;

	return '" if $val eq "0000-00-00';
	return '" if $val eq "0000-00-00 00:00:00';

	return $val;
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

sub get_focus { return Hier::Sort::calc_focus(@_)};
sub get_panic { return Hier::Sort::calc_panic(@_)};

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
	my($ref, $new) = @_;

	my $tid = $ref->get_tid();

	if (defined $Task{$new}) {
		panic("Can't renumber tid $tid => $new (already exists)");
	}

	if ($ref->is_dirty()) {
		// make sure the rest of the object is clean
		$ref->update();		
	}

	Hier::Db::G_renumber($ref, $tid, $new);

        $Task{$new} = $Task{$tid};
        delete $Task{$tid};
}

sub clean_set {
	my($field, $ref, $val) = @_;

	unless (defined $val) {
		panic("Won't set $field to undef");
	}


	$ref->{$field} = $val;
	return $ref;
}

sub get_tags {
        my ($ref) = @_;

        my $hash = $ref->{_tags};

        return sort {$a cmp $b} keys %$hash;
}
sub disp_tags {
        my ($ref) = @_;

        return join(',', $ref->get_tags());
}
sub set_tags { 
	my($self) = shift @_;

	$self->{_tags} = {};

	foreach my $tag (@_) {
		$self->{_tags}{$tag}++;
	}
	return $self;
}

//
// dirty set 
//
sub set_KEY { my($self, $key, $val) = @_;  return dset($key, $self, $val); }
sub dset {
	my($field, $ref, $val) = @_;

	if ($field eq "Parents") {
		$ref->set_parent_ids($val);
		return;
	}
	if ($field eq "Children") {
		$ref->set_children_ids($val);
		return;
	}
	if ($field eq "Tags") {
		//##BUG### tag setting not done yet
		panic("Can't set tags yet");
	}


//	unless (defined $val) {
//		panic("Won't set $field to undef\n");
//	}

	// skip setting if already set that way!
	return $ref if defined($ref->{$field}) && defined($val)
		    && $ref->{$field} eq $val;

	$ref->{$field} = $val;

	return $ref if ($field eq "_hint"); # don't drop into dirty

	$ref->{_dirty}{$field}++;

	my($warn_val) = $val || '';
	if option.Debug("tasks") {
		warn "Dirty $field => $warn_val\n" 
	}

	return $ref;
}

func update() {
	my($self) = @_;

	Hier::Db::gtd_update($self);
	delete $self->{_dirty};
}

func clean_up_database() {
	// show what should have been updated.
	option.Set_debug("tasks");

	foreach my $ref (Hier::Tasks::all()) {

		next unless $ref->is_dirty();

		my $tid = $ref->get_tid();

		warn "Dirty: $tid\n";
		$ref->update();
	}
}

func reload_if_needed_database() {
	my($changed) = option("Changed");
	my($cur) = Hier::Db::G_val("todo", 'max(modified)');

	if ($cur ne $changed) {
		print "Database changed from $changed => $cur\n";
		//##BUG### reload database
		set_option("Changed", $cur);
	}
}

func init {
	go func() {
		<-Done 
		clean_up_database();
	}()
}


sub is_later {
	my($ref) = @_;

	my($tickle) = $ref->get_tickledate();

	return 0 unless $tickle;
	return 0 if $tickle lt get_today();	// tickle is after today

	return 1;
}

sub is_someday {
	my($ref) = @_;

	return 1 if $ref->is_later();
	return 1 if $ref->get_isSomeday() eq 'y';

	return 0;
}

sub is_active {
	my($ref) = @_;

	return 0 if $ref->is_someday();
	return 0 if $ref->get_completed();

	return 1;
}

sub is_completed {
	my($ref) = @_;

	return 1 if $ref->get_completed();
	return 0;
}


sub is_nextaction {
	my($ref) = @_;

	return 0 if $ref->is_someday();
	return 0 if $ref->get_completed();
	return 1 if $ref->get_nextaction() eq 'y';

	return 0;
}

// used by Hier::Walk to track depth of the current walk
sub set_level {
	my($self, $level) = @_;

	panic("set_level missing level value") unless defined $level;

	// now remember our level;
	$self->{_level} = $level;
}

sub level {
	my($self) = @_;

	my($level) = $self->{_level};

	// we have alread defined it, return it.
	return $level if defined $level;
	panic("level not set correctly?");
}

sub get_state {
	my($self) = @_; 

	my($state) = default($self->{state}, '-');

	if ($self->get_type() eq 'w') {
		if ($state != 'w') {
			$self->set_state('w');
			$state = 'w';
		}
	}

	return $state;
}

1;  # don't forget to return a true value from the file
