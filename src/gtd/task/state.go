package task

//==============================================================================
// Kanban states
//------------------------------------------------------------------------------

type next_state_T struct {
	state string
	msg   string
}

var States_map = map[byte]next_state_T{
	'-': next_state_T{"a", "-new-"}, // never processed state.
	'a': next_state_T{"b", "Analysis Needed"},
	'b': next_state_T{"c", "Being Analysed"},
	'c': next_state_T{"d", "Completed Analysis"},
	'd': next_state_T{"f", "Doing"},
	'f': next_state_T{"t", "Finished Doing"},
	'i': next_state_T{"c", "Ick"},       // task stuck.
	'r': next_state_T{"c", "Reprocess"}, // Reprint
	't': next_state_T{"u", "Test"},
	'u': next_state_T{"z", "Update wiki"}, // done, file paperwork
	'w': next_state_T{"r", "Waiting"},     // Waiting on
	'z': next_state_T{"z", "Z all done"},  // should have a completed date
}

func bump(t *Task) string {

	state := t.State
	if state == 0 {
		state = '-'
	}

	if _, ok := States_map[state]; !ok {
		return "-"
	}

	new := States_map[state].state
	t.Set_state(new)

	//#  doing          and action then
	if new == "d" && t.Type == 'a' {
		// make sure its a next action
		t.Set_nextaction("y")
	}
	return new
}

func State(state byte) string {

	if msg, ok := States_map[state]; ok {
		return msg.msg
	}

	return "???$state???"
}
