package display

import "io"
import "os"
import "fmt"
import "strings"
import "strconv"

import "gtd/task"
import "gtd/color"
import "gtd/option"

//??	@EXPORT= qw( 
//?		&report_header &summary_children &format_summary
//?		&display_mode &display_fd_task &display_task
//?		&display_rgpa &display_hier
//?		&disp_ordered_dump


var format_Header  func(io.Writer, string) = header_none
var format_Display func(io.Writer, *task.Task, string) = disp_simple

var Display_fd = os.Stdout

func Header(note string) {
	format_Header(Display_fd, note)
}

func Task(ref *task.Task, note string) {
	format_Display(Display_fd, ref, note)
}


var Wiki bool = false		//### display is in wiki format ####

// task field order used by dump
var Order = []string {
	"todo_id",
	"type",
	"nextaction",
	"isSomeday",
".",
	"task",
	"description",
	"note",
".",
	"category",
	"context",
	"timeframe",
".",
	"created",
	"doit",
	"modified",
	"tickledate",
	"due",
	"completed",
	"recur",
	"recurdesc",
".",
	"resource",
	"priority",
	"state",
	"effort",
	"percent",
	"depends",
".",
}

// display.Mode sets the display format for report
func Mode(mode string) {
	alias := map[string]string{
		"todo": "doit",
		"pri": "priority",
	}

	// alias re-mappings
	mode = strings.ToLower(mode)
	if alias_mode, ok := alias[mode]; ok {
		mode = alias_mode
	}

	if mode == "wiki" {
		Wiki = true
	}

	func_mode := map[string]func(io.Writer,*task.Task,string) {
		"none"     : disp_none,
		"list"     : disp_title,	// same as title but no headers

		"tid"      : disp_tid,
		"title"    : disp_title,
		"item"     : disp_item,
		"simple"   : disp_simple,
		"summary"  : disp_summary,
		"detail"   : disp_detail,
		"action"   : disp_detail,

		"task"     : disp_task,
		"doit"     : disp_task,

		"plan"     : disp_plan,

		"html"     : disp_html,
		"wiki"     : disp_wiki,
		"walk"     : disp_wikiwalk,


		"d_csv"    : disp_doit_csv,
		"d_lst"    : disp_doit_list,

		"rpga"     : disp_rgpa,
		"rgpa"     : disp_rgpa,
		"hier"     : disp_hier,
		"priority" : disp_priority,

		"print"    : disp_print,

		"dump"     : disp_ordered_dump,
		"odump"    : disp_ordered_dump,

		"udump"    : disp_unordered_dump,

		"debug"    : disp_debug,
	}

	header_alias_map := map[string]string {
		"none"     : "none",
		"list"     : "none",	// same as title but no headers

		"tid"      : "report",
		"title"    : "report",
		"item"     : "report",
		"simple"   : "report",
		"summary"  : "report",
		"detail"   : "report",
		"action"   : "report",

		"task"     : "none",
		"plan"     : "none",

		"doit"     : "report",
		"html"     : "html",
		"wiki"     : "wiki",
		"walk"     : "wiki",

		"d_csv"    : "report",
		"d_lst"    : "report",

		"rpga"     : "rgpa",
		"rgpa"     : "rgpa",
		"hier"     : "hier",
		"priority" : "report",

		"dump"     : "none",

		"udump"    : "none",
		"sdump"    : "none",
		"odump"    : "none",
	}
	header_func_map := map[string]func(io.Writer, string){
		"none"     : header_none,
		"report"   : header_report,
		"html"     : header_html,
		"wiki"     : header_wiki,
		"walk"     : header_wiki,
		"rgpa"     : header_none,
		"hier"     : header_none,
	}

	if mode == "" {
		mode = "simple"
	}

	// process header modes
	if _,ok := func_mode[mode]; !ok {
		fmt.Printf("Unknown display mode: %s\n", mode)
		return
	}

	format_Display = func_mode[mode]

	header_mode := option.Get("Header", mode)

	header_alias, ok := header_alias_map[header_mode]; 
	if !ok {
		header_alias = "none"
	}

	header_func, ok := header_func_map[header_alias]; 
	if !ok {
		header_func = header_none
	}
	format_Header = header_func

	// pick sorting?
	return
}

//==============================================================================
/*?
sub report_header {
	my($title) = option("Title") || ""
	if (@_) {
		my($desc) = join(" ", @_) || ""

		if ($title and $desc) {
			$title .= " -- " . $desc
		} elsif ($title eq "") {
			$title = $desc
		}
	}

	unless ($Header) {
		display_mode("simple")
	}
	&$Header(\*STDOUT, $title)
}

sub summary_children {
	my($pref) = @_

	my $work_load = 0

	my $complet = 0
	my $counted = 0
	my $actions = 0

	for my $child ($pref->get_children()) {
		$complet++ if $child->is_completed()
		$actions++

		next unless $child->is_nextaction()
		$counted++ unless $child->filtered()

		$work_load++
	}

	return ($work_load, "($counted/$actions/$complet)")
}

?*/

//==============================================================================

func header_none(fd io.Writer, title string) {
}

func header_report(fd io.Writer, title string) {
//?	cols := Columns() - 2

//?	print {$fd} "#","=" x $cols; nl($fd)
//?	print {$fd} "#== $title";    nl($fd)
//?	print {$fd} "#","=" x $cols; nl($fd)

	fmt.Fprintf(fd, "#========");     color.Nl(fd)
	fmt.Fprintf(fd, "#== %s", title); color.Nl(fd)
	fmt.Fprintf(fd, "#========");     color.Nl(fd)
}

func header_wiki(fd io.Writer, title string) {
	fmt.Fprintf(fd, "== %s ==", title)
	color.Nl(fd)
}

func header_html(fd io.Writer, title string) {
	fmt.Fprintf(fd, "<h1>%s</h1>", title)
	color.Nl(fd)
}

/*?
sub display_fd_task {
	&$Display(@_)
}
?*/

func disp_none(fd io.Writer, t *task.Task, note string) {
	// no display
}

func disp_tid(fd io.Writer, t *task.Task, note string) {
	fmt.Fprintf(fd, "%d", t.Tid)
	color.Nl(fd)
}

func disp_title(fd io.Writer, t *task.Task, note string) {
	fmt.Fprintf(fd, "%s", t.Title)
	color.Nl(fd)
}

func disp_item(fd io.Writer, t *task.Task, note string) {
	desc := Summary(t.Description, " -- ")
	fmt.Fprintf(fd, "%d\t  [_] %s%s", t.Tid, t.Title, desc);
	color.Nl(fd)
}

func disp_simple(fd io.Writer, t *task.Task, note string) {
	fmt.Fprintf(fd, "%d:\t%s %s", t.Tid, Type(t), t.Title)
	if note != "" {
		fmt.Fprint(fd, " ", note)
	}
	color.Nl(fd)
}

func disp_detail(fd io.Writer, t *task.Task, note string) {
	disp_simple(fd, t, note)

	bulk_display("+", t.Description)
	bulk_display("=", t.Note)
	color.Nl(fd)
}

func disp_summary(fd io.Writer, t *task.Task, note string) {
	desc := Summary(t.Description, " -- ")
	disp_simple(fd, t, desc)
}

func disp_plan(fd io.Writer, t *task.Task, note string) {
/*?
	my($fd, $ref, $note) = @_

	my($tid) = $ref->get_tid()
	my($kind = type_disp($ref)
	my($title) = $ref->get_title()

	my($resource) = new Hier::Resource($ref)
	my($effort)  = $resource->effort()
	my($user)    = $resource->resource()
	my($why)     = $resource->hint()

	if ($note) {
		$note = " ".$note
	} elsif ($why) {
		$note = " ".color("BROWN")."$user ($why)".color()
	} else {
		$note = ""
	}

	print {$fd} "$tid:\t".
		color("GREEN")."$effort\t".color().
		"$kind$title$note"
?*/
	color.Nl(fd)
}

func Summary(val, sep string) string {
	if val == "" {
		return ""
	}

//?	return "" if $val =~ /^\s*[.\-\*]/

//?	$val =~ s=\n.*==s
//?	$val =~ s=\r.*==s

	if val == "" || val == "=" {
		return ""
	}

	return sep + val
}

func bulk_display(tag, text string) {
	if text == "" || text == "-" {
		return
	}

	for _,line := range strings.Split(text, "\n") {
		fmt.Printf("%s\t%s\n", tag, line)
	}
}

func disp_print(fd io.Writer, ref *task.Task, note string) {
/*?
	my $val
	for my $key (@Order) {
		next if $key =~ /^_/
		if ($key eq ".") {
			print $fd "\n"
			next
		}

		$val = $ref->get_KEY($key)
		if (defined $val) {
			chomp $val

			next if $val eq ""

			$val =~ s/\r//gm;	// all returns
			$val =~ s/^/\t\t/gm;	// tab at start of line(s)
			$val =~ s/^\t// if length($key) >= 7
			print $fd "$key:$val\n"
		} else {
			print $fd "#$key:\n"
		}
	}
	//##BUG### handle missing keys from @Ordered
	print $fd "Tags:\t", $ref->disp_tags(),"\n"
	print $fd "Parents:\t", $ref->disp_parents(),"\n"
	print $fd "Children:\t", $ref->disp_children(),"\n"
	print $fd "=-=\n"
?*/
	color.Nl(fd)
}

func disp_ordered_dump(fd io.Writer, ref *task.Task, note string) {
/*?
	my($fd, $ref) = @_

	my $val
	for my $key (@Order) {
		next if $key =~ /^_/
		if ($key eq ".") {
			print $fd "\n"
			next
		}

		$val = $ref->get_KEY($key)
		if (defined $val) {
			chomp $val
			$val =~ s/\r//gm;	// all returns
			$val =~ s/^/\t\t/gm;	// tab at start of line(s)
			$val =~ s/^\t// if length($key) >= 7
			print $fd "$key:$val\n"
		} else {
			print $fd "#$key:\n"
		}
	}
	//##BUG### handle missing keys from @Ordered
	print $fd "Tags:\t", $ref->disp_tags(),"\n"
	print $fd "Parents:\t", $ref->disp_parents(),"\n"
	print $fd "Children:\t", $ref->disp_children(),"\n"
	print $fd "=-=\n"
?*/
	color.Nl(fd)
}

func disp_unordered_dump(fd io.Writer, ref *task.Task, note string) {
	if note != "" {
		fmt.Printf("# %s\n", note)
	}
/*?
	for key, val := ref.Fields {
		if key[:1] = "_" {
			continue
		}

		if (defined $val) {
			chomp $val
			$val =~ s/\r//gm;	// all returns
			$val =~ s/^/\t\t/gm;	// tab at start of line(s)
			$val =~ s/^\t// if length($key) >= 7
			print $fd "$key:$val\n"
		} else {
			print $fd "#$key:\n"
		}
	}
	print $fd "Tags:\t", $ref->disp_tags(),"\n"
	print $fd "Parents:\t", $ref->disp_parents(),"\n"
	print $fd "Children:\t", $ref->disp_children(),"\n"
	print $fd "=-=\n"
?*/
	color.Nl(fd)
}

//? my($Hier_stack) = { "o" => 0, "g" => 0, "p" => 0 }

func display_hier(ref *task.Task, note string) {
/*?

	my($cols) = columns() - 2

	my $tid = $ref->get_tid()
	my $kind= $ref->get_type()
	my $title = $ref->get_title()

	if ($kindeq "o") {
		if ($Hier_stack->{o}) {
			print "#".("=" x $cols), "\n"
		}
		$Hier_stack = { "o" => $tid, "g" => 0, "p" => 0 }
		$note ||= ""
		print " [*** Role $tid: $title ***] $note\n"
		return
	}

	if ($kindeq "g") {
		if ($Hier_stack->{g} ne $tid) {
			display_hier($ref->get_parent())
			if ($Hier_stack->{g}) {
				print "#", "-" x $cols, "\n"
			}
			$Hier_stack->{g} = $tid
			$Hier_stack->{p} = 0
		}
	}

	if ($kindeq "p") {
		if ($Hier_stack->{p} ne $tid) {
			display_hier($ref->get_parent())
			$Hier_stack->{p} = $tid
		}
	}

	display_task($ref, $note)
?*/
}

var Prev_goal int
var Prev_role int

func header_rpga(fd io.Writer, title string) {
	Prev_goal = 0
	Prev_role = 0
}


func Rgpa(ref *task.Task, note string) {
/*?
	if note == "=" {
		Prev_role = 0
		note = ""
	}

	return unless $ref

	my $cols = columns() - 2
	my $tid  = $ref->get_tid()
	my $kind= $ref->get_type()

	if ($kindeq "o") {	// "o" == Role
		return if $tid == $Prev_role

		if ($Wiki) {
			display_task($ref, $note)
		} else {
			print "#", "=" x $cols, "\n" if $Prev_role != 0
			$note ||= ""
			print " [*** Role $tid: ", $ref->get_title(), " ***] $note\n"
		}
		$Prev_role = $tid
		$Prev_goal = 0
		return
	}
	if ($kindeq "g") {
		display_rgpa($ref->get_parent())

		return if $tid == $Prev_goal
		if ($Wiki) {
			display_task($ref, $note)
		} else {
			print "#", "-" x $cols, "\n" if $Prev_goal != 0
			display_task($ref, $note)
		}

		$Prev_goal = $tid
		return
	}
	display_rgpa($ref->get_parent())
	display_task($ref, $note)
?*/
}

func disp_wikiwalk(fd io.Writer, ref *task.Task, note string) {
/*?
	my(%type) = (
		"a" => "action",
		"p" => "project",
		"g" => "goal",
		"o" => "role",
		"v" => "vision",
		"m" => "value",
		"w" => "action",
		"?" => "fook",
	)

	my($kind = $ref->get_type()
	my($tid) =  $ref->get_tid()
	my($title) =  $ref->get_title()
	my($done) =  $ref->is_completed()

	$kind= "?" unless defined $type{$type}
	
	my($level) = $ref->level()

	print {$fd} "*" x $level

	print {$fd} "<del>" if $done
	print {$fd} "{{".$kind$type},"|$tid|$title"."}}"
	print {$fd} "</del>" if $done

	print {$fd} " -- $note" if $note

	nl({$fd})
?*/
}

func disp_wiki(fd io.Writer, ref *task.Task, note string) {
	type_name := map[byte]string {
		'a' : "action",
		'p' : "project",
		'g' : "goal",
		'o' : "role",
		'v' : "vision",
		'm' : "value",
		'w' : "action",
		'?' : "fook",
	}

	type_s := ref.Type
	if _,ok := type_name[type_s]; !ok {
		type_s = '?'
	}

//?	tid :=  ref.Tid
//?	title := ref.Title
//?	done := ref.Is_completed()

/*?
	print {$fd} "== " if $kind=~ /[ovm]/
	print {$fd} "=== " if $kindeq "g"
	print {$fd} "**" if $kindeq "a"
	print {$fd} "**(wait)" if $kindeq "w"
	print {$fd} "*" if $kindeq "p"

	print {$fd} "<del>" if $done
	print {$fd} "{{".$kind$type},"|$tid|$title"."}}"
	print {$fd} "</del>" if $done

	print {$fd} " -- $note" if $note

	print {$fd} " ===" if $kindeq "g"
	print {$fd} " ==" if $kind=~ /[ovm]/
	
?*/
	color.Nl(fd)
}

func disp_html(fd io.Writer, ref *task.Task, note string) {
/*?
	my(%type) = (
		"a" => "action",
		"p" => "project",
		"g" => "goal",
		"o" => "role",
		"v" => "vision",
		"m" => "value",
		"w" => "action",
		"?" => "fook",
	)

	my($kind = $ref->get_type()
	my($tid) =  $ref->get_tid()
	my($title) =  $ref->get_title()
	my($done) =  $ref->is_completed()

	$title =~ s|\[\[(.+?)\]\]|<a href=/dev/index.php?$1>$1</a>|

	$kind= "?" unless defined $type{$type}
	
	print {$fd} "<h2> " if $kind=~ /[ovm]/
	print {$fd} "<h3> " if $kindeq "g"
	print {$fd} "<ul>*" if $kindeq "a"
	print {$fd} "<ul>*(wait)" if $kindeq "w"
	print {$fd} "<ul>" if $kindeq "p"

	print {$fd} "<del>" if $done
	print {$fd} $kind$type}, ":[".
		"<a href=/todo/r617/itemReport.php?itemId=$tid>".
		"$tid</a>]$title"
	print {$fd} "</del>" if $done

	print {$fd} " -- $note" if $note

	print {$fd} " </h3>" if $kindeq "g"
	print {$fd} " </h2>" if $kind=~ /[ovm]/
	nl($fd)
?*/
}

func disp_task(fd io.Writer, ref *task.Task, note string) {
/*?
	my($fd, $ref, $note) = @_

	my($pri, $kind $context, $project, $action)
	$kind= $ref->get_type()

	$context = $ref->get_context() || ""
	$context = "\@$context" if $context

	if ($kindeq "a") {
		my($proj) = $ref->get_parent()
		if ($proj) {
			$project = $proj->get_title()
			$project =~ s/ /_/g
			$project = "/$project/"
		} else {
			$project = "//"
		}
	} else {
		$project = " ".type_name($kind.":"
	}
	$action = $ref->get_title()
	my($tid) = "[".$ref->get_tid()."]"

	if ($ref->is_nextaction()) {
		$pri = chr(ord("A") + $ref->get_priority() - 1)
	} else {
		$pri = chr(ord("c") + $ref->get_priority() - 1)
	}

	$pri = "S" if $ref->is_someday()
	$pri = "X" if $ref->is_completed()
	$pri = "V" if $kind=~ /[mv]/

	$pri = "I" if $kindeq "i"

	$pri = "R" if $kindeq "o"
	$pri = "Q" if $kindeq "g"
	$pri = "P" if $kindeq "p"

	$pri = "T" if $ref->get_tickledate() gt get_today()
	$pri = "L" if $kind=~ /[rLCT]/

	my($result) = join(" ", "($pri)", $context.$project, $action, $tid)
	$result =~ s/\s\s+/ /g
	print $result
	print " $note" if $note
	nl($fd)
?*/
}

func disp_debug(fd io.Writer, ref *task.Task, note string) {
/*?
	my($fd, $ref, $note) = @_

	my($pri, $kind $context, $project, $title)
	$kind= $ref->get_type()

	$context = $ref->get_context() || ""
	$context = "\@$context" if $context

	$title = $ref->get_title()

	$pri = $kind
	$pri .= "." . $ref->get_priority()
	$pri .= "." . $ref->get_panic()
	$pri .= "." . $ref->get_focus()
	$pri .= "." .  "[".$ref->get_tid()."]"

	$pri .= "N" if $ref->is_nextaction()
	$pri .= "S" if $ref->is_someday()
	$pri .= "X" if $ref->is_completed()

	if ($ref->get_tickledate()) {
		if ($ref->get_tickledate() gt get_today()) {
			$pri .= "T"
		} else {
			$pri .= "t"
		}
	}
	$pri =~ s/\.$//

	my($result) = join(" ", $pri, $context, $title)
	$result =~ s/\s\s+/ /g
	print $result
?*/
	color.Nl(fd)
}


func disp_rgpa(fd io.Writer, ref *task.Task, note string) {
	old := format_Display
	format_Display = disp_simple

	Rgpa(ref, note)

	format_Display = old
}

func disp_hier(fd io.Writer, t *task.Task, note string) {

//?	my $mask  = option("Mask")

	level := t.Level();

	tid  := t.Tid
	name := t.Title

	if level == 1 {
		color.Ref(t)
		fmt.Fprintf(fd, "===== %d -- %s ====================", tid, name)
		color.Nl(fd)
		return
	}
	if level == 2 {
		color.Ref(t)
		fmt.Fprintf(fd, "----- %d -- %s --------------------", tid, name)
		color.Nl(fd)
		return
	}

	//fmt.Fprintf(fd, "%d: %d -- %s", level, tid, name);

//?	my $cnt  = $ref->count_actions() || ""
//>	my $desc = format_summary($ref->get_description(), "")

	cnt := ""
//	pri := t.Priority
	desc := ""

	color.Ref(t)

	fmt.Fprintf(fd, "%5d %3s ", tid, cnt)
//	fmt.Fprintf(fd, "%-15s", $ref->task_mask_disp() if $mask

	s := strings.Repeat("|  ", level-3)
	fmt.Fprint(fd, s, "+-", Type(t), "-")

	if name == desc || desc == "" {
		fmt.Fprintf(fd, "%.50s",  name)
	} else {
		fmt.Fprintf(fd, "%.50s",  name + ": " + desc)
	}

	color.Nl(fd)
}

func disp_doit_csv(fd io.Writer, ref *task.Task, note string) {
/*?
	my($fd, $ref) = @_

	my($tid, $pri, $task, $cat, $created, $modified,
		$doit, $desc, $note, @desc)

	$tid = $ref->get_tid()

	$pri       = $ref->get_priority()

	$cat       = $ref->get_category() || ""
	$doit      = $ref->get_doit() || ""

	my($pref)  = $ref->get_parent()
	my($pname) = "-orphined-"
	if (defined $pref) {
		$pname    = $pref->get_title()
	}

	$task      = $ref->get_title() || $ref->get_context() || ""
	$desc      = $ref->get_description()

	$desc =~ s=\n.*==s
	print {$fd} join("\t", $tid, $pri, $cat, $doit, $pname, $task, $desc), "\n"
	//print join("\t", $tid, $pri, $cat, $task, $due, $desc), "\n"
?*/
}
	
var Count = 0

func header_doit_norm(fd io.Writer, title string) {
/*?
	return if $Count++

print <<"EOF"
  Id   Pri Category  Doit        Task/Description
==== === = ========= =========== ==============================================
EOF
?*/
}

func disp_doit_list(fd io.Writer, ref *task.Task, note string) {
/*?
	my($tid, $pri, $task, $cat, $created, $modified,
		$doit, $desc, $note, @desc)

format DOIT =
@>>> [_] @ @<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$tid,  $pri, $cat,       $doit,    $desc
~~                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                   $desc
.

//	header_doit_list()
	$~ = "DOIT";	// set STDOUT format name to HIER

	$tid = $ref->get_tid()

	$pri       = $ref->get_priority()

	$task      = $ref->get_title() || $ref->get_context() || ""
	$cat       = $ref->get_category() || ""
	$created   = $ref->get_created()
	$modified  = $ref->get_modified() || $created
	$doit      = $ref->get_doit() || ""
	$desc      = $ref->get_description()
	$note      = $ref->get_note()


	my(@parents) = ()
	my($pref) = $ref->get_parent()
	for (; $pref ; $pref = $pref->get_parent()) {
		my($info) = d_type($pref)

		unshift(@parents, $info)

		last if $info =~ /^G/
	}

	chomp $task
	chomp $desc
	chomp $note
	$note = "Outcome: $note" if $note

	$desc = join("\r", @parents,
		  "*[$tid] $task",
			split("\n", $desc),
			split("\n", $note)
	)

	write $fd
}

sub d_type {
	my($ref) = @_

	return undef unless defined $ref

	my $id      = $ref->get_tid()
	my $kind   = uc($ref->get_type())
	my $name    = $ref->get_title()

	chomp $name

	return "$kind[$id]: $name"
?*/
}

var display_Lines [] string
func next_line() string {
	if len(display_Lines) == 0 {
		return ""
	}

	v := display_Lines[0]
	display_Lines = display_Lines[1:]

	return v
}

func header_priority(fd io.Writer, title string) {
/*?
format PRIO_TOP =
  Id   Pri Category  Due         Task/Description: $title
==== === = ========= =========== ==============================================
.
?*/
}

func disp_priority(fd io.Writer, ref *task.Task, note string) {
/*?
	my($tid, $key, $pri, $task, $cat, $created, $modified, $due, $desc)

format PRIO =
@>>> @<< @ @<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$tid,$key,$pri, $cat,        $due,    $task
~~                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                                  $desc
.

	$~ = "PRIO";	// set STDOUT format name to PRIO

	$tid       = $ref->get_tid()
	$pri       = $ref->get_priority()

	$task      = $ref->get_title() || $ref->get_context() || ""
	$cat       = $ref->get_category() || ""
	$created   = $ref->get_created()
	$modified  = $ref->get_modified() || $created
	$due       = $ref->get_due()
	$desc      = $ref->get_description() || ""

	$key       = action_disp($ref)

	write

?*/
}

//==============================================================================
func Type(t *task.Task) string {
	if t.Is_task() && t.Is_completed() {
		return "<X>"
	}

	c := t.Type
	if t.Is_task() {
		c = '_'
	}

	if t.Is_completed() {
		return fmt.Sprintf("<%c>", c)
	}

	if t.Is_later() {
		return fmt.Sprintf("}%c{", c)
	}

	if t.Is_someday() {
		return fmt.Sprintf("{%c}", c)
	}
		
	if t.Is_nextaction() {
		return fmt.Sprintf("[%c]", c)
	}

	return fmt.Sprintf("(%c)", c)
}

func Nl() {
	color.Nl(Display_fd)
}

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
