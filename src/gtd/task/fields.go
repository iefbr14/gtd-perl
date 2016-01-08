package task

const (
	VALUE   = 'm' // hier
	VISION  = 'v'
	ROLE    = 'o'
	GOAL    = 'g'
	PROJECT = 'p'
	//	SUB_PROJECT	= 's'		// not real

	ACTION = 'a' // task(s)
	INBOX  = 'i'
	WAIT   = 'w'

	REFERENCE = 'r' // list(s)/references
	LIST      = 'L'
	CHECKLIST = 'C'
	ITEM      = 'T'
)


func (ref *Task) Is_task() bool {
	return	ref.Type == ACTION || 
		ref.Type == WAIT || 
		ref.Type == INBOX 
}

func (ref *Task) Is_hier() bool {
	return	ref.Type == VALUE ||
		ref.Type == VISION ||
		ref.Type == ROLE ||
		ref.Type == GOAL ||
		ref.Type == PROJECT
}

func (ref *Task) Is_list() bool {
	return	ref.Type == REFERENCE ||
		ref.Type == LIST || 
		ref.Type == CHECKLIST || 
		ref.Type == ITEM 
}
