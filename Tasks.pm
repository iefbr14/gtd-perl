package Hier::Tasks;

use strict;
use warnings;

use Hier::Option;

use base qw(Hier::Hier Hier::Fields Hier::Filter Hier::Format);

my %Task;		# all Todo items (including Hier)

sub find {
	my($tid) = @_;

	return unless defined $Task{$tid};
	return $Task{$tid};
}

sub all {
	return values %Task;
}

my $Max_todo = 0; 	# Last todo id (unique for all tables)
our $Debug = 0; 

sub new {
	my($class, $tid) = @_;

	my($self) = {};

	$Max_todo = Hier::Db::G_val('todo', 'max(todo_id)') unless $Max_todo;

	if (defined $tid) {
		die "Task $tid exists won't create it." if defined $Task{$tid};

		$Max_todo = $tid if $Max_todo < $tid;
	} else {
		$tid = ++$Max_todo;
	}

	$self->{todo_id} = $tid;

	$self->{_tags} = {};

	bless $self, $class;

	$Task{$tid} = $self;	# need to hide this

	return $self;
}

sub insert {
	my($self) = @_;

	Hier::Db::gtd_insert($self);
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
	delete $Task{$tid};

	Hier::Db::sac_delete($tid);
	Hier::Db::gtd_delete($tid);	# remove from database

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
sub get_todo_only    { my($self) = @_; return default($self->{_todo_only}, 0); }
sub get_type         { my($self) = @_; return default($self->{type}, '?'); }

sub get_resource     { my($self) = @_; return default($self->{resource}, ''); }
sub get_hint         { my($self) = @_; return default($self->{_hint}, ''); }

sub get_focus { return Hier::Sort::calc_focus(@_)};
sub get_panic { return Hier::Sort::calc_panic(@_)};

sub set_category     {return dset('category', @_); }
sub set_completed    {return dset('completed', @_); }
sub set_context      {return dset('context', @_); }
sub set_created      {return dset('created', @_); }
sub set_depends      {return dset('depends', @_); }
sub set_description  {return dset('description', @_); }
sub set_doit         {return dset('doit', @_); }
sub set_due          {return dset('due', @_); }
sub set_effort       {return dset('effort', @_); }
sub set_state        {return dset('state', @_); }
sub set_gtd_modified {return dset('gtd_modified', @_); }
sub set_isSomeday    {return dset('isSomeday', @_); }
sub set_later        {return dset('later', @_); }
sub set_live         {return dset('live', @_); }
sub set_mask         {return dset('mask', @_); }
sub set_modified     {return dset('modified', @_); }
sub set_nextaction   {return dset('nextaction', @_); }
sub set_note         {return dset('note', @_); }
sub set_priority     {return dset('priority', @_); }
sub set_title        {return dset('task', @_); }
sub set_tickledate   {return dset('tickledate', @_); }
sub set_timeframe    {return dset('timeframe', @_); }
sub set_todo_only    {return dset('_todo_only', @_); }
sub set_type         {return dset('type', @_); }

sub set_resource     {return dset('resource', @_); }
sub set_hint         {return dset('_hint', @_); }
sub hint_resource    {return clean_set('resource', @_); }

sub set_tid          {
	my($ref, $new) = @_;

	my $tid = $ref->get_tid();

	if (defined $Task{$new}) {
		die "Can't renumber tid $tid => $new (already exists)\n";
	}

	if ($ref->is_dirty()) {
		# make sure the rest of the object is clean
		$ref->update();		
	}

	Hier::Db::G_renumber($ref, $tid, $new);

        $Task{$new} = $Task{$tid};
        delete $Task{$tid};
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

	foreach my $tag (@_) {
		$self->{_tags}{$tag}++;
	}
	return $self;
}

#
# dirty set 
#
sub set_KEY { my($self, $key, $val) = @_;  return dset($key, $self, $val); }
sub dset {
	my($field, $ref, $val) = @_;

	if ($field eq 'Parents') {
		$ref->set_parents_ids($val);
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

	Hier::Db::gtd_update($self);
	delete $self->{_dirty};
}

sub clean_up_database {
	$Debug = 1;	# show what should have been updated.
	foreach my $ref (Hier::Tasks::all()) {

		next unless $ref->is_dirty();

		my $tid = $ref->get_tid();

		warn "Dirty: $tid\n";
		$ref->update();
	}
}

sub reload_if_needed_database {
	my($changed) = option('Changed');
	my($cur) = Hier::Db::G_val('todo', 'max(modified)');

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

# used by Hier::Walk to track depth of the current walk
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
	die "level not set correctly?";
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
