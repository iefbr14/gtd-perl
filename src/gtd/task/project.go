package task

import "fmt"

type Project_T struct {
	task   *Task
	name   string
	why    string
	effort string
	how    string
	user   string
}

var Resources map[string]map[string]string

// task.Project creates access to Project level meta data
func (t *Task) Project() *Project_T {
	r := new(Project_T)
	r.task = t

	return r
}

// resource.Resource looks up a task's resource which can be
//  inharited from its parent
func (r Project_T) Resource() string {
	resource := r.name
	if resource != "" {
		return resource
	}

	t := r.task

	resource = t.Resource
	if resource != "" {
		r.name = resource
		return resource
	}

	resource, reason := calc_resource(t)

	r.name = resource
	r.why = reason
	return resource
}

func calc_resource(t *Task) (string, string) {

	resource := t.Resource
	if resource != "" {
		return resource, "resource" // handle recursion
	}

	kind := t.Type

	/*?
		if ($desc =~ /^allocate:(\S+)$/) {
			//##TODO verify $1 in resource list
			return ($1, "allocate")
		}
	?*/

	if name, ok := Resources["category"][t.Category]; ok {
		return name, "category"
	}

	if name, ok := Resources["context"][t.Context]; ok {
		return name, "context"
	}

	if kind == 'g' {
		if name, ok := Resources["goal"][t.Title]; ok {
			return name, "goal"
		}

	}

	if kind == 'r' {
		if name, ok := Resources["role"][t.Title]; ok {
			return name, "role"
		}
	}

	//? my(@tags) = t->get_tags()
	//##TODO look up data in resource list

	// ok maybe the parent resource.
	pt := t.Parent()

	// nope, we are orfaned or top level
	if pt == nil {
		return "personal", "top"
	}

	return calc_resource(pt)
}

// resource.Hint returns where the resource name comes from
func (r Project_T) Hint() string {
	if r.why == "" {
		r.Effort() // force effort calcuation
	}
	return r.why
}

// resource.How  returns the effort and how it was calculated
func (r *Project_T) How() string {
	effort := r.Effort()
	if r.how != "" {
		effort += " # " + r.how
	}
	return effort
}

// resource.Effort returns the effort in human scaled form
func (r *Project_T) Effort() string {
	if r.effort != "" {
		return r.effort
	}

	t := r.task
	if t.Effort > 0 {
		r.effort = fmt.Sprintf("%dh", t.Effort)
	}

	if r.effort == "" {
		switch t.Type {
		default:
			r.effort = "1h # action"
		case 'p':
			r.effort = "2h # Need planning"
		case 'g':
			r.effort = "8h # Need planning"
		}
	}

	kind := t.Type

	/*?
	desc := t.Description
	if ($desc =~ /^pages:(\d+)$/m) {
	  //	$effort =  int($1 / 30) . "h # $1 pages"
		$effort =  "1h # $1 pages"
	}
	if ($desc =~ /^effort:(\d+[hd])$/m) {
		$effort = $1
	}
	?*/
	if r.effort == "" {
		//##TODO have these in the resource list
		efforts := map[string]string{
			"Quick": "1h",
			"Hour":  "2h",
			"Day":   "8h",
			"Week":  "5d",
			"Month": "20d",
			"Year":  "100d",
		}

		if e, ok := efforts[t.Timeframe]; ok {
			r.effort = e
			r.how = t.Timeframe
		} else {
			r.effort = "1h # action"
			if kind == 'p' {
				r.effort = "2h"
				r.how = "project needs planning"
			}
			if kind == 'g' {
				r.effort = "8h"
				r.how = "goal needs planning"
			}
		}
	}

	if kind == 'a' {
		return r.effort
	}

	if len(t.Children) == 0 {
		return r.effort
	}

	//***BUG*** need to gather the effort of the children
	return r.effort
}

func (r Project_T) Hours() int {
	t := r.task

	effort := t.Effort
	/*
		if effort == 0 {
			return 0
		}

			if ($effort =~ m/^([.\d]+)h.*$/) {
				return $1
			}
			if ($effort =~ m/^([.\d]+)d.*$/) {
				return $1 * 4
			}
	*/
	return effort
}

func complete() {
}

// for each action, grouped by resource, sorted by priority/hier.task-id
// tag it as depending on the previous resource
func predecessor() {

}
