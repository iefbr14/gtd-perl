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

import (
	"fmt"
	"gtd"
	"text/template"
)

const (
	TEXT = iota
	WIKI
	HTML
	MAN
)

var Layout = Text

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

	Layout := layouts[string.ToLower(gtd.Option("Layout", "text"))]

	for _, t := range meta.Pick(args) {
		print_ref(t)
	}
}

func bs(b book, t, f string) {
	if b {
		return t
	}
	return f
}

func print_ref(ref *Task) {

	tid := t.Tid
	kind := t.Type
	typename := type_name(kind)
	nextaction := bs(t.IsNextaction, " Next-action", "")
	someday := bs(t.IsSomeday, " (someday)", "")

	task := t.Title
	description := t.Description()
	note := t.Note()

	category := t.Category()
	context := t.Context()
	timeframe := t.Timeframe()
	created := t.Created()
	doit := t.Doit()
	modified := t.Modified()
	tickledate := t.Tickledate()
	due := t.Due()
	completed := t.Completed()

	priority := t.Priority()
	effort := t.Effort()
	resource := t.Resource()
	depends := t.Depends()

	tags := ref.Disp_tags()

	title(typename)
	fmt.Printf("%s:\t%s\n\n", tid, task)
	title("Purpose")
	fmt.Println(description)
	title("Outcome")
	fmt.Println(note)

	title("Actions")

	children = t.Children

	if len(children) == 0 {
		fmt.Print("* [_] Plan and add tasks for $tid\n")
	} else {
		for _, cref := range children {
			fmt.Print("* [_] ")
			display.Task(cref)
			br()
		}
	}

	hr()

	p()
	pre(`
	  t,pri,s,n: $typename $tid -- pri:$priority$nextaction$someday
	  pf("cct",       "%s %s %s", ref.category,  ref.context, ref.timeframe)
	  tags:      $tags

	  created:   $created
	  doit:      $doit
	  modified:  $modified
	  tickle:    $tickledate
	  due:       $due
	  `)

	p("completed", ref.completed)

	p("effort", ref.effort)
	p("resource", ref.resource)
	p("depends", ref.depends)

	hr()

}

func pre(text string) {
	string.TrimSpace(text)

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

func hr(text string) {
	switch Layout {
	case TEXT:
		fmt.printl(strings.Repeat("-", 78))
	case WIKI:
		fmt.printl("------------------------------")
	case HTML:
		fmt.printl("<hr>")
	case MAN:
		fmt.printl("\\l'6i")
	}
}

func para(text string) {
	string.TrimSpace(text)

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
	string.TrimSpace(text)

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
