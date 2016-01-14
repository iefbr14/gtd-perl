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

	/*?
		// everybody into the pool by id
		meta.ilter("+any", '^tid', "doit");

		Layout := layouts[string.ToLower(gtd.Option("Layout", "text")))];

		for ref := range meta.ick(args)) {
			print_ref(ref);
		}
	?*/
}

func print_ref(ref *Task) {
	/*?
	  	my($ref) = @_;

	  	my($tid)         = $ref->get_tid();
	  	my($type)        = $ref->get_type();
	  	my($typename)    = type_name($type);
	  	my($nextaction)  = $ref->is_nextaction() ? " Next-action" : '';
	  	my($someday)      = $ref->is_someday() ? " (someday)" :'';

	  	my($task)        = $ref->get_title();
	  	my($description) = $ref->get_description();
	  	my($note)        = $ref->get_note();

	  	my($category)    = $ref->get_category();
	  	my($context)     = $ref->get_context();
	  	my($timeframe)   = $ref->get_timeframe();
	  	my($created)     = $ref->get_created();
	  	my($doit)        = $ref->get_doit();
	  	my($modified)    = $ref->get_modified();
	  	my($tickledate)  = $ref->get_tickledate();
	  	my($due)         = $ref->get_due();
	  	my($completed)   = $ref->get_completed();

	  	my($priority)    = $ref->get_priority();
	  	my($effort)      = $ref->get_effort();
	  	my($resource)    = $ref->get_resource();
	  	my($depends)     = $ref->get_depends();

	  	my($tags)        = $ref->disp_tags();


	  	title($typename);   print "$tid:\t$task\n\n";
	  	title("Purpose");   print $description, "\n";
	  	title("Outcome");   print $note, "\n";

	  	title("Actions");

	  	my(@children) =$ref->get_children();

	  	if (@children == 0) {
	  		print "* [_] Plan and add tasks for $tid\n";
	  	}

	  	for my $cref (@children) {
	  		print "* [_] ";
	  		display_task($cref);
	  		br();
	  	}

	  	hr();

	  	p
	  	pre(<<"EOF");
	  t,pri,s,n: $typename $tid -- pri:$priority$nextaction$someday
	  pf("cct",       "%s %s %s", ref.category,  ref.context, ref.timeframe)
	  tags:      $tags

	  created:   $created
	  doit:      $doit
	  modified:  $modified
	  tickle:    $tickledate
	  due:       $due
	  p("completed", ref.completed)

	  p("effort",    ref.effort)
	  p("resource",  ref.resource)
	  p("depends",   ref.depends)

	  EOF

	  	hr();

	  ?*/
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
