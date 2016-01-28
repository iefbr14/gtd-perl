package task

import "log"
import "sort"
import "strings"
import "strconv"

func rel_add(list Tasks, task *Task) Tasks {
	list = rel_del(list, task)
	list = append(list, task)

	sort.Sort(list)
	return list
}

func rel_del(list Tasks, task *Task) Tasks {
	last := len(list) - 1

	// just return the empty list if already empty
	if last < 0 {
		return list
	}

	for i, t := range list {
		if t == task {
			list[i] = list[last]
			list[last] = nil

			return list[:last]
		}
	}
	return list
}

//------------------------------------------------------------------------------
// core routines.  Only these add/remove relationships
//
func (parent *Task) Add_child(child *Task) {
	child.Parents = rel_add(child.Parents, parent)
	parent.Children = rel_add(parent.Children, child)

	child.set_dirty("parents")
}

func (parent *Task) Orphin_child(child *Task) {
	child.Parents = rel_del(child.Parents, parent)
	parent.Children = rel_del(parent.Children, child)

	child.set_dirty("parents")
}

func (child *Task) Add_parent(parent *Task) {
	parent.Children = rel_add(parent.Children, child)
	child.Parents = rel_add(child.Parents, parent)

	parent.set_dirty("parents")
}

//------------------------------------------------------------------------------
// access routines but they don't change anything.

func (t *Task) Parent_ids() []int {
	list := make([]int, 0, len(t.Parents))
	for _, t := range t.Parents {
		list = append(list, t.Tid)
	}
	sort.Ints(list)
	return list
}

func (t *Task) Children_ids() []int {
	list := make([]int, 0, len(t.Children))
	for _, t := range t.Children {
		list = append(list, t.Tid)
	}
	sort.Ints(list)
	return list
}

//------------------------------------------------------------------------------
// helper routines they do useful things, but don't know interals

/*?
sub count_actions {
	my(@children) = get_children(@_)

	my($count) = 0
	foreach my $child (get_children(@_)) {
		++$count if $child->get_type() eq 'a'
	}
	return $count
}
?*/

func (t *Task) Parent() *Task {
	if len(t.Parents) < 1 {
		return nil
	}

	return t.Parents[0]
}

/*?
sub safe_parent {
        my ($ref) = @_

        return "fook" unless defined $ref

	my $type = $ref->get_type()
        return "vision" if defined $type && $type eq 'm'

	my(@parent_ids) = $ref->parent_ids()

        return "orphin" unless @parent_ids

        return $parent_ids[0]
}

?*/
func (t *Task) Disp_parents() string {
	s := ""
	for _, p := range t.Parents {
		s += "," + strconv.Itoa(p.Tid)
	}
	if len(s) == 0 {
		return ""
	}
	return s[1:]
}

func (t *Task) Disp_children() string {
	s := ""
	for _, c := range t.Children {
		s += "," + strconv.Itoa(c.Tid)
	}
	if len(s) == 0 {
		return ""
	}
	return s[1:]
}

/*?

sub parent_id {
	my($self) = @_

	return ${$self->parent_ids()}[0]
}

sub has_parent_id {
	my($self, $check_parent_id) = @_

	foreach my $parent ($self->parent_ids()) {
		return 1 if $check_parent_id == $parent
	}
	return 0
}
?*/

//------------------------------------------------------------------------------
// set_parent_ids is used by dset in Tasks.pm
//
func (self *Task) Set_parent_ids(val string) {
	pids := strings.Split(val, ",")

	var pid_map map[int]*Task

	// find my new parents
	for _, pid_s := range pids {
		pid, _ := strconv.Atoi(pid_s)
		p := Find(pid)
		if p == nil { // opps not a real parent
			log.Printf("No parent id: %d\n", pid)
			continue
		}

		pid_map[pid] = p
	}

	// keep parent if already have that one, it otherwise disown it.
	for _, ref := range self.Parents {
		pid := ref.Tid

		if _, ok := pid_map[pid]; ok {
			// keeping this one.
			delete(pid_map, pid)
		} else {
			// disown parent
			ref.Orphin_child(self)
		}
	}

	// for my new parents add self as thier child
	for _, pref := range pid_map {
		pref.Add_child(self)
	}
}

func (t *Task) set_children_ids(val string) {
	cid_list := strings.Split(val, ",")

	cid_map := make(map[int]*Task)

	// find my new parents
	for _, task_id := range cid_list {
		cid, err := strconv.Atoi(task_id)
		if err != nil {
			log.Printf("Invalid child id: %d\n", cid)
			continue
		}

		c_ref := Find(cid)
		if c_ref == nil { // opps not a real child
			log.Printf("No child id: %d\n", cid)
			continue
		}

		cid_map[cid] = c_ref
	}

	// keep child if already have that one, it otherwise disown it.
	for _, ref := range t.Children {
		cid := ref.Tid

		if _, ok := cid_map[cid]; ok {
			delete(cid_map, cid) // keeping this one.
		} else {
			// disown parent
			t.Orphin_child(ref)
		}
	}
	// for my new children add self as their parent
	for _, cref := range cid_map {
		t.Add_child(cref)
	}
}

// check to see if some thas has the dep task as a decendent
func (parent *Task) Has_decendent(dep *Task) bool {
	for _, child := range parent.Children {
		if child == dep {
			return true
		}
		if child.Has_decendent(dep) {
			return true
		}
	}
	return false
}
