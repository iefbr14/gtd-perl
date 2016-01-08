package task

//? @EXPORT 	&type_name &type_val &type_depth
//?		&type_disp &action_disp

import "os"
import "strconv"

var Types = map[string]byte{
	"Value":  'm',
	"Vision": 'v',

	"Role":   'o',
	"Goal":   'g',

	"Project":     'p',
	"Sub-Project": 's', // we can as for this

	"Action":  'a',
	"Next":    'n', // next action
	"Inbox":   'i',
	"Wait":    'w',
	"Waiting": 'w',

	"Reference": 'r',

	"List":      'L',
	"Checklist": 'C',
	"Item":      'T',
}

var type_name_map map[byte]string

func init() {
	for key, val := range Types {
		type_name_map[val] = key
	}
}

/*
func type_val(val string)byte {
	id := val[0]
	if name, ok := type_name_map[id]; ok {
		return id
	}

	type_name := strings.ToTitle(val);

	if id, ok := Types[type_name]; ok {
		return id
	}
	type_name = append(type_name, "s");

	if id, ok = Types[type_name]; ok {
		return id
	}
	return 0;
}

func Type_name(type_id byte)string {
	return type_name_map[type];
}

func Type_depth(type_id byte)int {
	depth = map[byte]int(
		'm' : 1,		// hier
		'v' : 2,
		'o' : 3,
		'g' : 4,
		'p' : 5,
		's' : 6,		// sub-projects

		'n' : 7,		// next actions
		'a' : 7,		// actions (tasks)
		'i' : 8,		// inbox
		'w' : 8,		// wait for
	);

	if val, ok := depth[type_id]; ok {
		return val
	}

	panic(fmt.Sprintf("Bad type %s", type_id));
}

sub type_disp {
	my($ref) = @_;
	my($type) = $ref->get_type();

	return "<X>"     if $ref->is_task() && $ref->get_completed();
	$type = '_'      if $ref->is_task();

	return "<$type\>" if $ref->get_completed();

	return "}$type\{" if $ref->is_later();
	return "{$type\}" if $ref->is_someday();
	return "[$type\]" if $ref->is_nextaction();
	return "($type\)";
}

sub action_disp {
	my($ref) = @_;

	return  "<*>" if $ref->get_completed();

	my($key) = "(_)";
	$key = "[_]" if $ref->is_nextaction();

	$key =~ s/.(.)./\}$1\{/	if $ref->is_later();
	$key =~ s/.(.)./\{$1\}/ if $ref->is_someday();
	$key =~ s/.(.)./\>$1\</	if $ref->get_type() eq 'w';

	return $key;
}
*/

//==============================================================================

func Lines() int {
	lines := os.Getenv("LINES")
	if lines == "" {
		return 24
	}

	if val, err := strconv.Atoi(lines); err == nil {
		return val
	}
	return 24
}

func Columns() int {
	rows := os.Getenv("ROWS")
	if rows == "" {
		return 80
	}

	if val, err := strconv.Atoi(rows); err == nil {
		return val
	}
	return 80
}
