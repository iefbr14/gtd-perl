package report

/*
NAME:

=head1 USAGE

=head1 REQUIRED ARGUMENTS

=head1 OPTION

=head1 DESCRIPTION

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE and COPYRIGHT

(C) Drew Sullivan 2015 -- LGPL 3.0 or latter

=head1 HISTORY

*/

import "fmt"
import "strings"

import "gtd/display"
import "gtd/meta"
import "gtd/task"
import "gtd/color"

//import "gtd/option"

var (
	Lines      int
	Cols       int
	board_Seen map[*task.Task]bool
)

func Report_board(args []string) int {
	// counts use it and it give a context
	meta.Filter("+active", "^age", "simple")

	list := meta.Pick(args)

	if len(list) == 0 {
		list = meta.Pick([]string{"role"})
	}

	Lines = display.Lines()
	Cols = (display.Columns() / 4) - (1 + 5 + 1)

	board_Seen = make(map[*task.Task]bool)

	// rdebug("### Columns: %d split %d\n", display.Columns(), Cols)

	for _, t := range list {
		check_a_role(t)
	}
	return 0
}

/*
=head

For each role display:

Anal  |  Doing    |  Test | Done

Each column

TID: Keyword

Colors:

Green:  inprogress
Red:    data incomplete
Purple: overcommited

*/

type board_list_S struct {
	list []string
}

func check_a_role(role_ref *task.Task) {
	// check if we can even do the headers
	if last_lines(3) {
		return
	}
	display.Rgpa(role_ref, "")

	var (
		want             board_list_S
		b_anal, d_anal   board_list_S
		b_devel, d_devel board_list_S
		b_test, d_test   board_list_S
		b_done, d_done   board_list_S
	)

	board := []*task.Task{}
	list := []*task.Task{role_ref}

	for len(list) > 0 {
		t := list[0]
		list = list[1:] // shift list

		if board_Seen[t] {
			continue
		}
		board_Seen[t] = true

		kind := t.Type

		if kind == 'p' {
			board = append(board, t)
			continue
		}
		if t.Is_hier() {
			list = append(list, t.Children...)
		}

	}

	for _, t := range task.Tasks(board).Sort() {
		check_group(t, '-', 5, &want)

		check_group(t, 'b', 1, &d_anal)
		//------------------------------------------
		check_group(t, 'a', 1, &b_anal)

		check_group(t, 'd', 2, &d_devel) // Do
		check_group(t, 'i', 2, &d_devel) // Ick
		//------------------------------------------
		check_group(t, 'c', 2, &b_devel)

		check_group(t, 'r', 3, &d_test)
		check_group(t, 't', 3, &d_test)
		//------------------------------------------
		check_group(t, 'f', 3, &b_test)
		check_group(t, 'w', 2, &b_test) // wait

		check_group(t, 'u', 4, &d_done) // update
		//------------------------------------------
		check_group(t, 'z', 4, &b_done)
	}

	// fmt.Printf("%v\n", d_anal)
	// fmt.Printf("------------------\n")
	// fmt.Printf("%v\n", b_anal)
	// fmt.Printf("==================\n")

	c_anal := j(d_anal, b_anal)
	c_devel := j(d_devel, b_devel)
	c_test := j(d_test, b_test)
	c_done := j(d_done, b_done)

	color.Print("BOLD")
	f := fmt.Sprintf("----- %c-%ds ", '%', Cols) //  f = '%-13s'
	fmt.Printf(f, "Analyse")
	fmt.Printf(f, "Devel")
	fmt.Printf(f, "Test")
	fmt.Printf("----- %s", "Complete")
	display.Nl()

	if last_lines(3) {
		return
	}
	for len(c_anal.list) > 0 ||
		len(c_devel.list) > 0 ||
		len(c_test.list) > 0 ||
		len(c_done.list) > 0 {

		col(&c_anal, " ")
		col(&c_devel, " ")
		col(&c_test, " ")
		col(&c_done, "\n")

		if last_lines(1) {
			return
		}
	}

	if len(want.list) > 0 {
		fmt.Print(strings.Repeat("-", display.Columns()-1), "\n")
		if last_lines(1) {
			return
		}
	}

	for len(want.list) > 0 {
		col(&want, " ")
		col(&want, " ")
		col(&want, " ")
		col(&want, "\n")

		if last_lines(1) {
			return
		}
	}
}

func j(a, b board_list_S) board_list_S {
	dash := strings.Repeat("-", Cols+6)

	slice := make([]string, len(a.list)+1+len(b.list))

	l := len(a.list)

	copy(slice[:l], a.list)
	slice[l] = dash
	copy(slice[l+1:], b.list)

	v := board_list_S{slice}
	return v
}

func last_lines(lines int) bool {

	rdebug("%-3d ", Lines)

	if Lines <= 0 {
		return true
	}

	Lines -= lines

	if Lines <= 0 {
		fmt.Print("----- more ----\n")
		return true
	}
	return false
}

func col(aref *board_list_S, sep string) {
	val := ""

	if len(aref.list) > 0 {
		val = aref.list[0]
		aref.list = aref.list[1:]
	} else {
		if sep == " " {
			// val needs to be padded
			val = strings.Repeat(" ", Cols+6)
		}
	}

	fmt.Printf("%s%s", val, sep)
}

func check_group(t *task.Task, want byte, how int, board *board_list_S) {
	state := t.State

	if state != want {
		return
	}

	ret_color := ""

	switch how {
	case 1:
		ret_color = check_empty(t)

	case 2:
		ret_color = check_children(t)

	case 3:
		ret_color = check_done(t)

	case 4:
		ret_color = check_done(t)

	case 5:
		ret_color = check_want(t)
		if ret_color == "" {
			ret_color = check_empty(t)
		}
	}

	if state == 'w' && ret_color == "" {
		ret_color = color.On("CYAN")
	}

	if state == 'i' && ret_color == "" {
		ret_color = color.On("CYAN")
	}

	if state == 'r' && ret_color == "" {
		ret_color = color.On("BROWN")
	}

	save_item(ret_color, t, board)
	if state == 'd' {
		grab_child(t, board)
	}
}

func save_item(disp_color string, t *task.Task, board *board_list_S) {

	tid := t.Tid
	title := task.StripWiki(t.Title)

	// f := "%5d %-13.13s"
	f := fmt.Sprintf("%s %c-%d.%ds", "%5d", '%', Cols, Cols)

	result := disp_color +
		fmt.Sprintf(f, tid, title) +
		color.Off()

	board.list = append(board.list, result)
}

func grab_child(pref *task.Task, board *board_list_S) {
	for _, child := range pref.Children {
		if child.Is_completed() {
			continue
		}
		if child.Is_someday() {
			continue
		}

		if child.Is_nextaction() {
			save_item(color.On("LIME"), child, board)
			return
		}
	}
}

func check_want(pref *task.Task) string {

	title := pref.Title

	// title =~ /\[\[.*\]\]/)
	if strings.Index(title, "[[") >= 0 {
		return color.On("GREEN")
	}
	return ""
}

func check_empty(pref *task.Task) string {
	if pref == nil {
		return ""
	}

	children := 0
	for _, t := range pref.Children {
		children++
		if t.Is_completed() {
			continue
		}

		return color.On("PINK")
	}

	if children > 0 {
		return color.On("PURPLE")
	}
	return ""
}

func check_done(pref *task.Task) string {
	if pref == nil {
		return ""
	}

	for _, t := range pref.Children {
		if t.Completed != "" {
			continue
		}

		return color.On("PURPLE")
	}
	return ""
}

func check_children(pref *task.Task) string {

	count := 0
	next := 0
	done := 0

	for _, t := range pref.Children {
		count++
		if t.Is_nextaction() {
			next++
		}
		if t.Is_completed() {
			done++
		}
	}

	if count == 0 {
		return color.On("BROWN")
	}
	if next == 0 {
		return color.On("RED")
	}

	if count == done {
		return color.On("PURPLE")
	}

	if pref.State == 'w' {
		return color.On("CYAN")
	}
	return color.On("GREEN")
}
