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

var format_Header func(io.Writer, string) = header_none
var format_Display func(io.Writer, *task.Task, string) = disp_simple

var Display_fd = os.Stdout

func Header(note string) {
	format_Header(Display_fd, note)
}

/*?
sub report_Header {
	my($title) = option("Title") || ""
	if (@_) {
		my($desc) = task.Join(" ", @_) || ""

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
?*/

func Task(ref *task.Task, note string) {
	format_Display(Display_fd, ref, note)
}

var Wiki bool = false //### display is in wiki format ####

// task field order used by dump
var Order = []string{
	"todo_id",
	"type",
	"nextaction",
	"issomeday",
	".",
	"title",
	"description",
	"note",
	".",
	"category",
	"context",
	"timeframe",
	".",
	"created",
	"modified",
	"doit",
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
		"pri":  "priority",
	}

	// alias re-mappings
	mode = strings.ToLower(mode)
	if alias_mode, ok := alias[mode]; ok {
		mode = alias_mode
	}

	if mode == "wiki" {
		Wiki = true
	}

	func_mode := map[string]func(io.Writer, *task.Task, string){
		"none": disp_none,
		"list": disp_title, // same as title but no headers

		"tid":     disp_tid,
		"title":   disp_title,
		"item":    disp_item,
		"simple":  disp_simple,
		"summary": disp_summary,
		"detail":  disp_detail,
		"action":  disp_detail,

		"task": disp_task,
		"doit": disp_task,

		"plan": disp_plan,

		"html": disp_html,
		"wiki": disp_wiki,
		"walk": disp_wikiwalk,

		"d_csv": disp_doit_csv,
		"d_lst": disp_doit_list,

		"rpga":     disp_rgpa,
		"rgpa":     disp_rgpa,
		"hier":     disp_hier,
		"priority": disp_priority,

		"print": disp_print,

		"dump": disp_dump,

		"raw": disp_raw,

		"debug": disp_debug,
	}

	header_alias_map := map[string]string{
		"none": "none",
		"list": "none", // same as title but no headers

		"tid":     "report",
		"title":   "report",
		"item":    "report",
		"simple":  "report",
		"summary": "report",
		"detail":  "report",
		"action":  "report",

		"task": "none",
		"plan": "none",

		"doit": "report",
		"html": "html",
		"wiki": "wiki",
		"walk": "wiki",

		"d_csv": "report",
		"d_lst": "report",

		"rpga":     "rgpa",
		"rgpa":     "rgpa",
		"hier":     "hier",
		"priority": "report",

		"dump": "none",
		"raw":  "none",
	}
	header_func_map := map[string]func(io.Writer, string){
		"none":   header_none,
		"report": header_report,
		"html":   header_html,
		"wiki":   header_wiki,
		"walk":   header_wiki,
		"rgpa":   header_none,
		"hier":   header_none,
	}

	if mode == "" {
		mode = "simple"
	}

	// process header modes
	if _, ok := func_mode[mode]; !ok {
		fmt.Printf("Unknown display mode: %s\n", mode)
		return
	}

	format_Display = func_mode[mode]

	header_mode := option.Get("Header", mode)

	header_alias, ok := header_alias_map[header_mode]
	if !ok {
		header_alias = "none"
	}

	header_func, ok := header_func_map[header_alias]
	if !ok {
		header_func = header_none
	}
	format_Header = header_func

	// pick sorting?
	return
}

//==============================================================================

func Summary_children(t *task.Task) (int, string) {

	work_load := 0

	complet := 0
	counted := 0
	actions := 0

	for _, child := range t.Children {
		if child.Completed != "" {
			complet++
		}
		actions++

		if child.Is_nextaction() {
			continue
		}
		if !child.Filtered() {
			counted++
		}

		work_load++
	}

	note := fmt.Sprintf("(%d/%d/%d)", counted, actions, complet)
	return work_load, note
}

//==============================================================================

func header_none(fd io.Writer, title string) {
}

func header_report(fd io.Writer, title string) {
	cols := Columns() - 2

	fmt.Fprintf(fd, "%s%s", "#", strings.Repeat("=", cols))
	color.Nl(fd)
	fmt.Fprintf(fd, "#== %s", title)
	color.Nl(fd)
	fmt.Fprintf(fd, "%s%s", "#", strings.Repeat("=", cols))
	color.Nl(fd)
}

func header_wiki(fd io.Writer, title string) {
	fmt.Fprintf(fd, "== %s ==", title)
	color.Nl(fd)
}

func header_html(fd io.Writer, title string) {
	fmt.Fprintf(fd, "<h1>%s</h1>", title)
	color.Nl(fd)
}

func display_task(t *task.Task, note string) {
	format_Display(Display_fd, t, note)
}

func display_fd_task(fd io.Writer, t *task.Task, note string) {
	format_Display(fd, t, note)
}

//===========================================================================
// Actual report task displayers
//===========================================================================
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
	fmt.Fprintf(fd, "%d\t  [_] %s%s", t.Tid, t.Title, desc)
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
	r := t.Project()
	user := r.Resource()
	why := r.Hint()

	if note != "" {
		note = " " + note
	} else {
		if why != "" {
			note = " " + color.On("BROWN") + user + " (" + why + color.Off()
		}
	}

	fmt.Fprintf(fd, "%d:\t%s %s%s%s",
		t.Tid,
		color.On("GREEN")+r.Effort()+color.Off(),
		Type(t), t.Title, note)
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

	for _, line := range strings.Split(text, "\n") {
		fmt.Printf("%s\t%s\n", tag, line)
	}
}

func disp_print(fd io.Writer, ref *task.Task, note string) {
	for _, key := range Order {
		if key == "." {
			fmt.Fprint(fd, "\n")
			continue
		}

		val := Chomp(ref.Get_KEY(key))

		if val == "" {
			continue
		}

		//	$val =~ s/\r//gm;	// all returns
		//	$val =~ s/^/\t\t/gm;	// tab at start of line(s)
		//	$val =~ s/^\t// if length($key) >= 7
		fmt.Fprintf(fd, "%s:%s\n", key, val)
	}
	//##BUG### handle missing keys from @Ordered
	fmt.Fprint(fd, "Tags:\t", ref.Disp_tags(), "\n")
	fmt.Fprint(fd, "Parents:\t", ref.Disp_parents(), "\n")
	fmt.Fprint(fd, "Children:\t", ref.Disp_children(), "\n")
	fmt.Fprint(fd, "=-=\n")
	color.Nl(fd)
}

func Chomp(s string) string {
	//***BUG*** re-write to this form
	//	for l := len(s); l > 0; --l {
	//		if s[l] == '\r' || s[l] == '\n' {
	//			continue
	//		}
	//		s = s[:l]
	//	}
	return strings.TrimRight(s, "\r\n")
}

func disp_dump(fd io.Writer, t *task.Task, note string) {
	if note != "" {
		fmt.Printf("# %s\n", note)
	}

	for _, key := range Order {
		if key == "." {
			fmt.Fprint(fd, "\n")
			continue
		}

		val := t.Get_KEY(key)

		//	val =~ s/\r//gm;	// all returns
		if len(key) >= 7 {
			fmt.Fprintf(fd, "%s:\t", key)
		} else {
			fmt.Fprintf(fd, "%s:\t\t", key)
		}
		for _, c := range val {
			if c == '\n' {
				fmt.Fprint(fd, "\n\t\t")
				//fd.WriteString("\t\t\n")
				continue
			}
			fmt.Fprintf(fd, "%c", c) //***BUG*** there has to be a better way
			//fd.WriteRune(fd, c)
		}
		fmt.Fprint(fd, "\n")

	}
	//##BUG### handle missing keys from @Ordered
	fmt.Fprintf(fd, "Tags:\t%s\n", t.Disp_tags())
	fmt.Fprintf(fd, "Parents:\t%s\n", t.Disp_parents())
	fmt.Fprintf(fd, "Children:\t%s\n", t.Disp_children())
	fmt.Fprint(fd, "=-=\n")
}

func Dump(fd io.Writer, t *task.Task) {
	disp_dump(fd, t, "")
}

func disp_raw(fd io.Writer, t *task.Task, note string) {
	if note != "" {
		fmt.Printf("# %s\n", note)
	}

	fmt.Fprintf(fd, "%#v\n", t)
	/*?
		for key, val := t.Fields {
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
		print $fd "Tags:\t", $t->disp_tags(),"\n"
		print $fd "Parents:\t", $t->disp_parents(),"\n"
		print $fd "Children:\t", $t->disp_children(),"\n"
		print $fd "=-=\n"
	?*/
	color.Nl(fd)
}

//? my($Hier_stack) = { "o" => 0, "g" => 0, "p" => 0 }

func display_hier(t *task.Task, note string) {
	panic(".... code display_hier")
	/*?

		my($cols) = columns() - 2

		my $tid = $t->get_tid()
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

// display_rgpa => display.Rgpa -- display Role/Goal/Proj hier
func Rgpa(t *task.Task, note string) {
	if note == "=" {
		Prev_role = 0
		note = ""
	}

	if t == nil {
		return
	}

	cols := Columns() - 2
	tid := t.Tid
	kind := t.Type

	if kind == 'o' { // "o" == Role
		if tid == Prev_role {
			return
		}

		if Wiki {
			display_task(t, note)
		} else {
			if Prev_role != 0 {
				fmt.Printf("#%s\n", strings.Repeat("=", cols))
			}
			fmt.Printf(" [*** Role %d: %s ***] %s\n",
				tid, t.Title, note)
		}
		Prev_role = tid
		Prev_goal = 0
		return
	}

	if kind == 'g' {
		Rgpa(t.Parent(), "")

		if tid == Prev_goal {
			return
		}

		if Wiki {
			display_task(t, note)
		} else {
			if Prev_goal != 0 {
				fmt.Printf("#%s\n", strings.Repeat("=", cols))
			}
			display_task(t, note)
		}

		Prev_goal = tid
		return
	}
	Rgpa(t.Parent(), "")
	display_task(t, note)
}

func disp_wikiwalk(fd io.Writer, t *task.Task, note string) {
	panic(".... code disp_wikiwalk")
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

func disp_wiki(fd io.Writer, t *task.Task, note string) {
	type_name := map[byte]string{
		'a': "action",
		'p': "project",
		'g': "goal",
		'o': "role",
		'v': "vision",
		'm': "value",
		'w': "action",
	}

	kind := t.Type
	kind_name, ok := type_name[kind]
	if !ok {
		kind_name = "fook"
	}

	done := t.Is_completed()

	//?	tid :=  t.Tid
	//?	title := t.Title
	//?	done := t.Is_completed()

	switch kind {
	case 'o', 'v', 'm':
		fmt.Print(fd, "== ")
	case 'g':
		fmt.Print(fd, "=== ")
	case 'a':
		fmt.Print(fd, "**")
	case 'w':
		fmt.Print(fd, "** (wait)")
	case 'p':
		fmt.Print(fd, "*")
	}

	if done {
		fmt.Print(fd, "<del>")
	}

	fmt.Fprintf(fd, "{{%d|%s|%s}}", kind_name, t.Tid, t.Title)

	if done {
		fmt.Print(fd, "</del>")
	}

	if t.Note != "" {
		fmt.Print(fd, " -- %s", note)
	}

	switch kind {
	case 'g':
		fmt.Print(fd, " ===")
	case 'o', 'v', 'm':
		fmt.Print(fd, " ==")

	}
	color.Nl(fd)
}

func disp_html(fd io.Writer, t *task.Task, note string) {
	panic(".... code disp_html")
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

func disp_task(fd io.Writer, t *task.Task, note string) {
	kind := t.Type

	context := t.Context
	if context != "" {
		context = "@" + context
	}

	project := ""
	if kind == 'a' {
		proj := t.Parent()
		project = "//"
		if proj != nil {
			project = "/" + strings.Replace(proj.Title, " ", "_", -1) + "/"
		}
	} else {
		project = " " + task.Type_name(kind) + ":"
	}
	action := t.Title
	tid := fmt.Sprintf("[%d]", t.Tid)

	var pri string
	if t.Is_nextaction() {
		pri = string(byte((int('A') + t.Priority - 1)))
	} else {
		pri = string(byte((int('c') + t.Priority - 1)))
	}

	switch {

	case t.Is_someday():
		pri = "S"
	case t.Is_completed():
		pri = "X"
	case kind == 'm' || kind == 'v':
		pri = "V"
	case kind == 'i':
		pri = "I"
	case kind == 'o':
		pri = "R"
	case kind == 'g':
		pri = "Q"
	case kind == 'p':
		pri = "P"
	case t.Tickledate > option.Today(0):
		pri = "T"
	case kind == 'r', kind == 'L', kind == 'C', kind == 'T':
		pri = "L"
	}

	fmt.Printf("(%s) %s.%s %s %s", pri, context, project, action, tid)
	if note != "" {
		fmt.Printf(" %s", note)
	}
	color.Nl(fd)
}

func disp_debug(fd io.Writer, t *task.Task, note string) {

	//my($pri, $kind $context, $project, $title)

	pri := fmt.Sprintf("%c.[%d].%d", t.Type, t.Tid, t.Priority)

	//? pri += "." . ref->get_panic()
	//? pri += "." . ref->get_focus()

	if t.Is_nextaction() {
		pri += "N"
	}
	if t.Is_someday() {
		pri += "S"
	}
	if t.Is_completed() {
		pri += "X"
	}

	if t.Tickledate != "" {
		if t.Tickledate > option.Today(0) {
			pri += "T"
		} else {
			pri += "t"
		}
	}
	//? pri =~ s/\.$//

	result := task.Join(pri, t.Context, t.Title)
	// $result =~ s/\s\s+/ /g
	fmt.Fprint(fd, result)
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

	level := t.Level()

	tid := t.Tid
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
		fmt.Fprintf(fd, "%.50s", name)
	} else {
		fmt.Fprintf(fd, "%.50s", name+": "+desc)
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

var display_Lines []string

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

func Text(text string) {
	fmt.Fprint(Display_fd, text)
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
