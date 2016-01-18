package task

import "fmt"
import "strings"

//? @EXPORT 	&type_name &type_val &type_depth
//?		&type_disp &action_disp

var Types = map[string]byte{
	"Value":  'm',
	"Vision": 'v',

	"Role": 'o',
	"Goal": 'g',

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
	type_name_map = make(map[byte]string)
	for key, val := range Types {
		type_name_map[val] = key
	}
}

// task.Type_val maps things like role/goal to types r or g
func Type_val(val string) byte {
	id := val[0]
	if _, ok := type_name_map[id]; ok {
		return id
	}

	type_name := strings.Title(val)
	fmt.Printf("#=== Type_val(%s) => %s\n", val, type_name)

	if id, ok := Types[type_name]; ok {
		return id
	}
	type_name += "s"

	if id, ok := Types[type_name]; ok {
		return id
	}
	return 0
}

// task.Type_name converts type like r or g to Role/Goal
func Type_name(kind byte) string {
	return type_name_map[kind]
}

func Type_depth(kind byte) int {
	depth := map[byte]int{
		'm': 1, // hier
		'v': 2,
		'o': 3,
		'g': 4,
		'p': 5,
		's': 6, // sub-projects

		'n': 7, // next actions
		'a': 7, // actions (tasks)
		'i': 8, // inbox
		'w': 8, // wait for
	}

	if val, ok := depth[kind]; ok {
		return val
	}

	panic(fmt.Sprintf("Bad type %c", kind))
}

/*?
sub action_disp {
	my($ref) = @_

	return  "<*>" if $ref->get_completed()

	my($key) = "(_)"
	$key = "[_]" if $ref->is_nextaction()

	$key =~ s/.(.)./\}$1\{/	if $ref->is_later()
	$key =~ s/.(.)./\{$1\}/ if $ref->is_someday()
	$key =~ s/.(.)./\>$1\</	if $ref->get_type() eq 'w'

	return $key
}
*/

//==============================================================================
func Join(args ...string) string {
	l := 0
	for _, s := range args {
		l += len(s)
	}

	if l == 0 {
		return ""
	}
	bs := make([]byte, l)

	bl := 0
	for _, s := range args {
		bl += copy(bs[bl:], s)
	}
	return string(bs)
}

// task.EmptyLine return true if it is a blank or comment line
func EmptyLine(s string) bool {
	for _, c := range s {
		// line starts with blanks
		if c == ' ' || c == '\t' {
			continue
		}

		// first non-blank character is a '#'
		if c == '#' {
			return true
		}

		// nope, not a comment line
		return false
	}

	// nothing but blanks it must be empty
	return true
}
