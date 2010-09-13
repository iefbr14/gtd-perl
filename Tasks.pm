package Hier::Tasks;

use strict;
use warnings;

our $VERSION     = 1.00;

use base qw(Hier::Hier Hier::Fields Hier::Filter);

use Hier::db;
use Hier::Hier;
use Hier::CCT;
use Hier::Sort;

my $Max_todo = 0; 	# Last todo id (unique for all tables)
my %Task;		# all Todo items (including Hier)
my $Debug = 1; 

sub new {
	my($class, $tid) = @_;

	my($self) = {};

	if (defined $tid) {
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

	gtd_insert($self);
}

sub find {
	my($tid) = @_;

	return unless defined $Task{$tid};
	return $Task{$tid};
}

sub max {
	return $Max_todo;
}

sub all {
	return values %Task;
}

sub hier {
	return grep { $_->is_ref_hier() } values %Task;
}

sub sorted {
	return Hier::Sort::sorted(@_);
}

sub matching_type {
	my($type) = @_;

	return grep { $_->get_type() eq $type } values %Task;
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

	Hier::db::sac_delete($tid);
	Hier::db::gtd_delete($tid);	# remove from database
	return;
}

#------------------------------------------------------------------------------

sub default { my($val, $default) = @_; return $val if defined $val; return $default; }
sub get_KEY { my($self, $key) = @_;  return default($self->{$key}, ''); }

sub get_tid          { my($self) = @_; return $self->{todo_id}; }

sub get_actions      { my($self) = @_; return default($self->{_actions}, undef); }
sub get_category     { my($self) = @_; return default($self->{category}, ''); }
sub get_categoryId   { my($self) = @_; return default($self->{categoryId}, 0); }
sub get_completed    { my($self) = @_; return default($self->{completed}, ''); }
sub get_context      { my($self) = @_; return default($self->{context}, ''); }
sub get_created      { my($self) = @_; return default($self->{created}, ''); }
sub get_depends      { my($self) = @_; return default($self->{depends}, ''); }
sub get_description  { my($self) = @_; return default($self->{description}, ''); }
sub get_doit         { my($self) = @_; return default($self->{doit}, ''); }
sub get_due          { my($self) = @_; return default($self->{due}, ''); }
sub get_effort       { my($self) = @_; return default($self->{effort}, '?'); }
sub get_isSomeday    { my($self) = @_; return default($self->{isSomeday}, 'n'); }
sub get_later        { my($self) = @_; return default($self->{later}, ''); }
sub get_live         { my($self) = @_; return default($self->{live}, 1); }
sub get_mask         { my($self) = @_; return default($self->{mask}, undef); }
sub get_modified     { my($self) = @_; return default($self->{modified}, ''); }
sub get_nextaction   { my($self) = @_; return default($self->{nextaction}, 'n'); }
sub get_note         { my($self) = @_; return default($self->{note}, ''); }
sub get_priority     { my($self) = @_; return default($self->{priority}, 3); }
sub get_title        { my($self) = @_; return default($self->{task}, ''); }
sub get_task         { my($self) = @_; return default($self->{task}, ''); }
sub get_tickledate   { my($self) = @_; return default($self->{tickledate}, ''); }
sub get_timeframe    { my($self) = @_; return default($self->{timeframe}, ''); }
sub get_todo_only    { my($self) = @_; return default($self->{_todo_only}, 0); }
sub get_type         { my($self) = @_; return default($self->{type}, '?'); }

sub get_resource     { my($self) = @_; return default($self->{resource}, ''); }

sub set_category     {return dset('category', @_); }
sub set_categoryId   {return dset('categoryId', @_); }
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
sub set_tid          {return dset('todo_id', @_); }
sub set_todo_only    {return dset('_todo_only', @_); }
sub set_type         {return dset('type', @_); }

sub set_resource     {return dset('resource', @_); }
sub hint_resource    {return clean_set('resource', @_); }

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

	unless (defined $val) {
		die "Won't set $field to undef\n";
	}
	$ref->{_dirty}{$field}++;

	$ref->{$field} = $val;

	print "Dirty $field => $val\n" if $Debug;

	return $ref;
}

sub update {
	my($self) = @_;

	gtd_update($self);
}

1;  # don't forget to return a true value from the file


