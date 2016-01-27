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

import "gtd/meta"
import "gtd/option"
import "gtd/task"
import "gtd/display"

const (
	TEXT = iota
	WIKI
	HTML
	MAN
)

var Layout int = TEXT

//-- display records in dump format based on format type
func Report_print(args []string) int {
	layouts := map[string]int{
		"text": TEXT,
		"wiki": WIKI,
		"html": HTML,
		"man":  MAN,
	}

	// everybody into the pool by id
	meta.Filter("+any", "^tid", "doit")

	Layout = layouts[strings.ToLower(option.Get("Layout", "text"))]

	for _, t := range meta.Pick(args) {
		print_ref(t)
	}
	return 0
}

func b2s(b bool, t, f string) string {
	if b {
		return t
	}
	return f
}

func print_ref(t *task.Task) {

	tid := t.Tid
	kind := t.Type
	typename := task.Type_name(kind)
	nextaction := b2s(t.IsNextaction, " Next-action", "")
	someday := b2s(t.IsSomeday, " (someday)", "")

	title(typename)
	fmt.Printf("%d:\t%s\n\n", t.Tid, t.Title)
	title("Purpose")
	fmt.Println(t.Description)
	title("Outcome")
	fmt.Println(t.Note)

	title("Actions")

	children := t.Children

	if len(children) == 0 {
		fmt.Printf("* [_] Plan and add tasks for %d\n", tid)
	} else {
		for _, cref := range children {
			fmt.Print("* [_] ")
			display.Task(cref, "")
			br()
		}
	}

	hr()

	fmt.Printf("priority   %d -- %s%s\n",
		t.Priority, nextaction, someday)

	fmt.Printf("cct        %s / %s / %s\n", t.Category, t.Context, t.Timeframe)
	fmt.Printf("tags       %s\n", t.Disp_tags())

	p("doit", t.Doit)
	p("modified", t.Modified)
	p("tickle", t.Tickledate)
	p("due", t.Due)

	r := t.Project()
	p("effort", r.Effort())
	p("resource", r.Resource())
	p("depends", t.Depends)

	hr()

}

func p(key, val string) {
	fmt.Printf("%-10s %s\n", key, val)
}

func pre(text string) {
	strings.TrimSpace(text)

	switch Layout {
	case TEXT:
		print("$text\n")
	case WIKI:
		print("<pre>$text</pre>\n\n")
	case HTML:
		print("<pre> $text <preh1>\n")
	case MAN:
		print(".EX\n$text\n.EE\n")
	}
}

func br() {
	switch Layout {
	case TEXT:
	case WIKI:
		print("<br>\n")
	case HTML:
		print("<br>\n")
	case MAN:
		print(".br\n")
	}
}

func hr() {
	switch Layout {
	case TEXT:
		fmt.Println(strings.Repeat("-", 78))
	case WIKI:
		fmt.Println("------------------------------")
	case HTML:
		fmt.Println("<hr>")
	case MAN:
		fmt.Println("\\l'6i")
	}
}

func para(text string) {
	strings.TrimSpace(text)

	switch Layout {
	case TEXT:
		fmt.Printf("%s\n", text)
	case WIKI:
		fmt.Printf("== %s ==\n\n", text)
	case HTML:
		fmt.Printf("<h1> %s </h1>\n", text)
	case MAN:
		fmt.Printf(".SH \"%s\"\n", text)
	}
}

func title(text string) {
	strings.TrimSpace(text)

	switch Layout {
	case TEXT:
		fmt.Printf("== %s ==\n\n", text)
	case WIKI:
		fmt.Printf("== %s ==\n\n", text)
	case HTML:
		fmt.Printf("<h1> %s </h1>\n", text)
	case MAN:
		fmt.Printf(".SH \"%s\"\n", text)
	}
}
