package GTD::Tasks;

use strict;
use warnings;

#use Class::Struct;
use GTD::Option;
use GTD::Project;

use base qw(GTD::Hier GTD::Fields GTD::Filter GTD::Format);

my %Tasks;		# all Todo items (including Hier)

#struct(
#	Tid     	=> '$',		# int
#	Type		=> '$',		# byte
#
#        Title      	=> '$',		# string
#        Description 	=> '$',		# string
#        Note       	=> '$',		# string
#
#        Category    	=> '$',		# string
#        Context     	=> '$',		# string
#
#        Doit        	=> '$',		# time.Time
#        Due         	=> '$',		# time.Time
#        Completed   	=> '$',		# time.Time
#        Effort      	=> '$',		# time.Duration
#
#        Priority   	=> '$',		# int
#        IsSomeday   	=> '$',		# bool
#        Later       	=> '$',		# time.Time
#        IsNextaction 	=> '$',		# bool
#
#        Created     	=> '$',		# time.Time
#        Modified   	=> '$',		# time.Time
#
#        live       	=> '$',		# bool
#        mask       	=> '$',		# uint
#
#        Tickledate 	=> '$',		# time.Time
#        Timeframe  	=> '@',		# []time.Time
#
#        Resource 	=> '@',		# []string
#        Hint     	=> '@',		# []string
#        Tags    	=> '@',		# []string
#
#        Depends     	=> '@',		# []* Task
#        Parents     	=> '@',		# []* Task
#        Children    	=> '@',		# []* Task
#
#	dirty		=> '%',		# map[string]bool
#);


sub find {
	my($tid) = @_;

	return unless defined $Tasks{$tid};
	return $Tasks{$tid};
}

sub all {
	return values %Tasks;
}

my $Max_todo = 0; 	# Last todo id (unique for all tables)
our $Debug = 0;

sub New {
	my($class, $tid) = @_;

	my($self) = {};

	$Max_todo = GTD::Db::G_val('itemstatus', 'max(itemId)') unless $Max_todo;

	if (defined $tid) {
		die "Task $tid exists won't create it." if defined $Tasks{$tid};

		$Max_todo = $tid if $Max_todo < $tid;
	} else {
		$tid = ++$Max_todo;
	}

	$self->{todo_id} = $tid;

	$self->{_tags} = {};

	bless $self, $class;

	$Tasks{$tid} = $self;	# need to hide this

	return $self;
}

sub insert {
	my($self) = @_;

	GTD::Db::gtd_insert($self);
	delete $self->{_dirty};
}

sub max {
	return $Max_todo;
}


#------------------------------------------------------------------------------
## Package Dirty
#
sub is_dirty {
	my($self) = @_;
	return defined $self->{_dirty};
}

sub get_dirty {
	my($self,$field) = @_;

	return 0 unless defined $self->{_dirty};
	return defined $self->{_dirty}{$field};
}

sub set_dirty {
	my($self, $field) = @_;

	$self->{_dirty}{$field} = 1;
	return $self;
}

sub clean_dirty {
	my($self) = @_;

	delete $self->{_dirty};
	return $self;
}

sub delete {
	my($self) = @_;

	my $tid = $self->{todo_id};
	delete $Tasks{$tid};

	# remove my children from self
	for my $child ($self->get_children()) {
		$self->orphin_child($child);
	}
	$self->update();

	# remove self from my parents
	for my $parent ($self->get_parents()) {
		$parent->orphin_child($self);
		$parent->update();
	}


	# commit suicide
	GTD::Db::gtd_delete($tid);	# remove from database

	###BUG### need to reflect back database changed.
	###G_sql("update");
	return;
}

#------------------------------------------------------------------------------

sub default {
	my($val, $default) = @_;

	return $default unless defined $val;

	return '' if $val eq '0000-00-00';
	return '' if $val eq '0000-00-00 00:00:00';

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
sub get_task         { die "call get title"; }
sub get_tickledate   { my($self) = @_; return default($self->{tickledate}, ''); }
sub get_timeframe    { my($self) = @_; return default($self->{timeframe}, ''); }
sub get_type         { my($self) = @_; return default($self->{type}, '?'); }

sub get_resource     { my($self) = @_; return default($self->{resource}, ''); }
sub get_hint         { my($self) = @_; return default($self->{_hint}, ''); }

sub get_focus { return GTD::Sort::calc_focus(@_)};
sub get_panic { return GTD::Sort::calc_panic(@_)};

sub set_category     {return dset('category', @_); }
sub set_completed    {return dset('completed', @_); }
sub set_context      {return dset('context', @_); }
sub set_created      {return dset('created', @_); }
sub set_depends      {return dset('depends', @_); }
sub set_description  {return dset('description', @_); }
sub set_doit         {return dset('doit', @_); }
sub set_due          {return dset('due', @_); }
sub set_effort       {return dset('effort', @_); }
sub set_gtd_modified {return dset('gtd_modified', @_); }
sub set_isSomeday    {return dset('isSomeday', @_); }
sub set_mask         {return dset('mask', @_); }
sub set_modified     {return dset('modified', @_); }
sub set_nextaction   {return dset('nextaction', @_); }
sub set_note         {return dset('note', @_); }
sub set_priority     {return dset('priority', @_); }
sub set_title        {return dset('task', @_); }
sub set_tickledate   {return dset('tickledate', @_); }
sub set_timeframe    {return dset('timeframe', @_); }
sub set_type         {return dset('type', @_); }

sub set_resource     {return dset('resource', @_); }
sub set_hint         {return dset('_hint', @_); }
sub hint_resource    {return clean_set('resource', @_); }

sub set_tid          {
	my($ref, $new) = @_;

	my $tid = $ref->get_tid();

	if (defined $Tasks{$new}) {
		die "Can't renumber tid $tid => $new (already exists)\n";
	}

	if ($ref->is_dirty()) {
		# make sure the rest of the object is clean
		$ref->update();
	}

	GTD::Db::G_renumber($ref, $tid, $new);

        $Tasks{$new} = $Tasks{$tid};
        delete $Tasks{$tid};
}

sub clean_set {
	my($field, $ref, $val) = @_;

	unless (defined $val) {
		die "Won't set $field to undef\n";
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

	for my $tag (@_) {
		$self->{_tags}{$tag}++;
	}
	return $self;
}

sub disp_type {
	my($ref) = @_;

	return GTD::Util::type_name($ref->get_type());
}

#
# dirty set
#
sub set_KEY { my($self, $key, $val) = @_;  return dset($key, $self, $val); }
sub dset {
	my($field, $ref, $val) = @_;

	if ($field eq 'Parents') {
		$ref->set_parent_ids($val);
		return;
	}
	if ($field eq 'Children') {
		$ref->set_children_ids($val);
		return;
	}
	if ($field eq 'Tags') {
		###BUG### tag setting not done yet
		die "Can't set tags yet";
	}


#	unless (defined $val) {
#		die "Won't set $field to undef\n";
#	}

	# skip setting if already set that way!
	return $ref if defined($ref->{$field}) && defined($val)
		    && $ref->{$field} eq $val;

	$ref->{$field} = $val;

	return $ref if ($field eq '_hint'); # don't drop into dirty

	$ref->{_dirty}{$field}++;

	my($warn_val) = $val || '';
	warn "Dirty $field => $warn_val\n" if $Debug;

	return $ref;
}

sub update {
	my($self) = @_;

	GTD::Db::gtd_update($self);
	delete $self->{_dirty};
}

sub clean_up_database {
	$Debug = 1;	# show what should have been updated.
	for my $ref (GTD::Tasks::all()) {

		next unless $ref->is_dirty();

		my $tid = $ref->get_tid();

		warn "Dirty: $tid\n";
		$ref->update();
	}
}

sub reload_if_needed_database {
	my($changed) = option('Changed');
	my($cur) = GTD::Db::G_val('itemstatus', 'max(lastModified)');

	if ($cur ne $changed) {
		print "Database changed from $changed => $cur\n";
		###BUG### reload database
		set_option('Changed', $cur);
	}
}

END {
	clean_up_database();
}


sub is_later {
	my($ref) = @_;

	my($tickle) = $ref->get_tickledate();

	return 0 unless $tickle;
	return 0 if $tickle lt get_today();	# tickle is after today

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

# used by GTD::Walk to track depth of the current walk
sub set_level {
	my($self, $level) = @_;

	die "set_level missing level value" unless defined $level;

	# now remember our level;
	$self->{_level} = $level;
}

sub level {
	my($self) = @_;

	my($level) = $self->{_level};

	# we have alread defined it, return it.
	return $level if defined $level;

	my($pref) = $self->get_parent();
	if ($pref) {
		$self->{_level} = $pref->level()+1;
	} else {
		$self->{_level} = 1
	}
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

sub Project {
	my($self) = @_;

	return new GTD::Project($self);
}

sub ref_context {
	my($ref) = @_;

	my($context) = $ref->get_context();

	return $context if $context;

	for my $pref ($ref->get_parents()) {
		$context = $pref->ref_context();

		return $context if $context;
	}
	return '';
}

sub ref_category {
	my($ref) = @_;

	my($category) = $ref->get_category();

	return $category if $category;

	for my $pref ($ref->get_parents()) {
		$category = $pref->ref_category();

		return $category if $category;
	}
	return '';
}

sub ref_timeframe {
	my($ref) = @_;

	my($timeframe) = $ref->get_timeframe();

	return $timeframe if $timeframe;

	for my $pref ($ref->get_parents()) {
		$timeframe = $pref->ref_timeframe();

		return $timeframe if $timeframe;
	}
	return '';
}


#==============================================================================
# Kanban states
#------------------------------------------------------------------------------

my %States = (
	'-' => ['a', '-new-', ],		# never processed state.
	'a' => ['b', 'Analysis Needed',	],
	'b' => ['c', 'Being Analysed',	],
	'c' => ['d', 'Completed Analysis', ],
	'd' => ['f', 'Doing',		],
	'f' => ['t', 'Finished Doing',	],
	'i' => ['a', 'Ick',		],	# task stuck.
	'r' => ['a', 'Reprocess',	],	# Reprint
	't' => ['u', 'Test',		],
	'u' => ['z', 'Update wiki',	],	# done, file paperwork
	'w' => ['r', 'Waiting',		],	# Waiting on
	'z' => ['z', 'Z all done',	], 	# should have a completed date
);

sub state_bump {
	my($ref) = @_;

	my ($state) = $ref->get_state();

	return unless defined $States{$state};

	my($new) = $States{$state}[0];

	$ref->set_state($new);

	##  doing          and action then
	if ($new eq 'd' && $ref->get_type() eq 'a') {
		# make sure its a next action
		$ref->set_nextaction('y');
	}
	return $new;
}

sub state_name {
	my($ref) = @_;

	my ($state) = $ref->get_state();

	return "???$state???" unless defined $States{$state};

	return $States{$state}[1];
}

sub set_state        {
	my($ref, $state) = @_;

	unless (defined $States{$state}) {
		return undef;
	}
	return dset('state', $ref, $state); 
}

1;  # don't forget to return a true value from the file
