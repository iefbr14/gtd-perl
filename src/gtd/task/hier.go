package task

import "log"
import "sort"
import "strings"
import "strconv"

func rel_add(list Tasks, task *Task) Tasks {
	list = rel_del(list, task);
	list = append(list, task);

	sort.Sort(list)
	return list;
}

func rel_del(list Tasks, task *Task) Tasks{
	last := len(list)-1
	
	// just return the empty list if already empty
	if last < 0 {
		return list
	}

	for i, t := range list {
		if t == task {
			list[i] = list[last]
			list[last]= nil

			return list[:last]
		}
	}
	return list;
}

//------------------------------------------------------------------------------
// core routines.  Only these add/remove relationships
//
func (parent *Task)add_child(child *Task) {
	child.Parents   = rel_add(child.Parents, parent);
	parent.Children = rel_add(parent.Children, child);

	child.set_dirty("parents");
}

func (parent *Task)orphin_child(child *Task) {
	child.Parents = rel_del(child.Parents, parent);
	parent.Children = rel_del(parent.Children, child);

	child.set_dirty("parents");
}


//------------------------------------------------------------------------------
// access routines but they don't change anything.

func (t *Task) Parent_ids() []int {
	list := make([]int, 0, len(t.Parents));
	for _, t := range t.Parents {
		list = append(list, t.Tid);
	}
	sort.Ints(list)
	return list
}

func (t *Task) Children_ids() []int {
	list := make([]int, 0, len(t.Children));
	for _, t := range t.Children {
		list = append(list, t.Tid);
	}
	sort.Ints(list)
	return list
}

//------------------------------------------------------------------------------
// helper routines they do useful things, but don't know interals

/*?
sub count_children {
	my(@children) = get_children(@_);

	//## see Hier::Format::summray_children for counts
	//## based on filters

	return scalar @children;
}

sub count_actions {
	my(@children) = get_children(@_);

	my($count) = 0;
	foreach my $child (get_children(@_)) {
		++$count if $child->get_type() eq 'a';
	}
	return $count;
}

sub get_parent {
	my($self) = @_;

	confess unless ref $self;

	my(@parents) = $self->get_parents();

	return $parents[0];
}

sub safe_parent {
        my ($ref) = @_;

        return "fook" unless defined $ref;

	my $type = $ref->get_type();
        return "vision" if defined $type && $type eq 'm';

	my(@parent_ids) = $ref->parent_ids();

        return "orphin" unless @parent_ids;

        return $parent_ids[0];
}

sub disp_parents {
        my ($ref) = @_;

        return join(',', $ref->parent_ids());
}

sub disp_children {
        my ($ref) = @_;

        return join(',', children_ids($ref));
}

sub parent_id {
	my($self) = @_;

	return ${$self->parent_ids()}[0];
}

sub has_parent_id {
	my($self, $check_parent_id) = @_;

	foreach my $parent ($self->parent_ids()) {
		return 1 if $check_parent_id == $parent;
	}
	return 0;
}
?*/

//------------------------------------------------------------------------------
// set_parent_ids is used by dset in Tasks.pm
//
func (self *Task) set_parent_ids(val string) {
	pids := strings.Split(val, ",");

	var pid_map map[int]*Task

	// find my new parents
	for _, pid_s := range pids {
		pid, _ := strconv.Atoi(pid_s)
		p := Find(pid);
		if p == nil { 	// opps not a real parent
			log.Printf("No parent id: %d\n", pid);
			continue;
		}

		pid_map[pid] = p
	}

	// keep parent if already have that one, it otherwise disown it.
	for _,ref := range self.Parents {
		pid := ref.Tid

		if _, ok := pid_map[pid]; ok {
			// keeping this one.
			delete(pid_map, pid);
		} else {
			// disown parent
			ref.orphin_child(self);
		}
	}

	// for my new parents add self as thier child
	for _, pref := range pid_map {
		pref.add_child(self);
	}
}

/*?
sub set_children_ids {
        my($self, $val) = @_;

	my(@cid) = split(',', $val);	// parent ids
	my(%cid);			// parent ids => parent ref

	// find my new parents
	for my $cid (@cid) {
		my $c_ref = Hier::Tasks::find($cid);
		unless ($c_ref) { # opps not a real child
			warn "No child id: $cid\n";
			next;
		}

		$cid{$cid} = $c_ref;
	}

	// keep child if already have that one, it otherwise disown it.
	for my $ref (rel_vals(child => $self)) {
		my $cid = $ref->get_tid();
		if (defined $cid{$cid}) {
			delete $cid{$cid};	// keeping this one.
		} else {
			// disown parent
			$self->orphin_child($ref);
		}
	}
	// for my new children add self as their parent
	for my $cref (values %cid) {
		add_child($self, $cref);
	}
}

?*/

