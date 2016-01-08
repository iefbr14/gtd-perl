// +build ignore
package task

//??	@EXPORT= qw( 
//?		&report_header &summary_children &summary_line
//?		&display_mode &display_fd_task &display_task
//?		&display_rgpa &display_hier
//?		&disp_ordered_dump


var Display = disp_simple;
var Header  = undef;

var Wiki := false;		//### display is in wiki format ####

// task field order used by dump
var Orrder []string{
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
	"owner",
	"palm_id",
	"priority",
	"state",
	"effort",
	"resource",
	"depends",
	"private",
	"percent",
".",
}

func display_mode(mode string) {
	alias := map[string]string{
		"todo": "doit",
		"pri": "priority",
	);

	// alias re-mappings
	mode = string.ToLower(mode);
	if alias_mode, ok := alias[mode]; ok {
		mode = alias_mode
	}

	if mode == "wiki" {
		Wiki = true;
	}

	func_mode := map[sring]func() {
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
	);

	header_alias := map[string]string {
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
	header_func := map[string]func(){
		"none"     : header_none,
		"report"   : header_report,
		"html"     : header_html,
		"wiki"     : header_wiki,
		"walk"     : header_wiki,
		"rgpa"     : header_rgpa,
		"hier"     : header_none,
	}

	if mode == "" {
		mode = "simple";
	}

	// process header modes
	if _,ok func_mode[mode]; !ok {
		fmt.Printf("Unknown display mode: %s\n", mode)
		return
	}

	Display = func_mode[mode];

	header_mode = option.String("Header", mode);

	if header_alias, ok = report_alias[header_mode]; !ok {
		header_alias = "none;
	}

	if Header, ok := header_func[mode]; !ok {
		Header = header_none;
	}

	// pick sorting?
	return;
}

//==============================================================================
sub report_header {
	my($title) = option("Title") || "";
	if (@_) {
		my($desc) = join(" ", @_) || "";

		if ($title and $desc) {
			$title .= " -- " . $desc;
		} elsif ($title eq "") {
			$title = $desc;
		}
	}

	unless ($Header) {
		display_mode("simple");
	}
	&$Header(\*STDOUT, $title);
}

sub summary_children {
	my($pref) = @_;

	my $work_load = 0;

	my $complet = 0;
	my $counted = 0;
	my $actions = 0;

	for my $child ($pref->get_children()) {
		$complet++ if $child->is_completed();
		$actions++;

		next unless $child->is_nextaction();
		$counted++ unless $child->filtered();

		$work_load++;
	}

	return ($work_load, "($counted/$actions/$complet)");
}

sub summary_line {
	return format_summary(@_);
}

//==============================================================================
func display_header() {
	&$Header(\*STDOUT, @_);
}

func header_none(fd io.Writer, title string) {
}

func header_report(fd io.Writer, title string) {
	my($cols) = columns() - 2;

	print {$fd} "#","=" x $cols; nl($fd);
	print {$fd} "#== $title";    nl($fd);
	print {$fd} "#","=" x $cols; nl($fd);
}

func header_wiki(fd io.Writer, title string) {
	my($fd, $title) = @_;

	print {$fd} "== $title ==\n";
}

func header_html(fd io.Writer, title string) {

	print {$fd} "<h1>$title</h1>\n";
}

sub display_task {
	&$Display(\*STDOUT, @_);
}

sub display_fd_task {
	&$Display(@_);
}

sub disp_none {
	// no display
}

sub disp_tid {
	my($fd, $ref) = @_;

	my($tid) = $ref->get_tid();

	print {$fd} $tid;
	nl($fd);
}

sub disp_title {
	my($fd, $ref) = @_;

	my($title) = $ref->get_title();

	print {$fd} $title;
	nl($fd);
}

sub disp_item {
	my($fd, $ref, $note) = @_;

	my($tid) = $ref->get_tid();
	my($type) = type_disp($ref);
	my($title) = $ref->get_title();

	my($desc) = format_summary($ref->get_description(), " -- ");
	print {$fd} "$tid\t  [_] $title$desc";
	nl($fd);
}

sub disp_simple {
	my($fd, $ref, $note) = @_;

	my($tid) = $ref->get_tid();
	my($type) = type_disp($ref);
	my($title) = $ref->get_title();

	if ($note) {
		$note = " ". $note;
	} else {
		$note = "";
	}


	print {$fd} "$tid:\t$type $title$note";
	nl($fd);
}

sub disp_detail {
	my($fd, $ref, $note) = @_;

	disp_simple(@_);

	bulk_display("+", $ref->get_description());
	bulk_display("=", $ref->get_note());
	nl($fd);
}

sub disp_summary {
	my($fd, $ref, $note) = @_;

	my($desc) = format_summary($ref->get_description(), " -- ");
	disp_simple(@_, $desc);
}

sub disp_plan {
	my($fd, $ref, $note) = @_;

	my($tid) = $ref->get_tid();
	my($type) = type_disp($ref);
	my($title) = $ref->get_title();

	my($resource) = new Hier::Resource($ref);
	my($effort)  = $resource->effort();
	my($user)    = $resource->resource();
	my($why)     = $resource->hint();

	if ($note) {
		$note = " ".$note;
	} elsif ($why) {
		$note = " ".color("BROWN")."$user ($why)".color();
	} else {
		$note = "";
	}

	print {$fd} "$tid:\t".
		color("GREEN")."$effort\t".color().
		"$type $title$note";
	nl($fd);
}


sub format_summary {
	my($val, $sep, $ishtml) = @_;

	return "" unless $val;
	return "" if $val =~ /^\s*[.\-\*]/;

	$val =~ s/\n.*//s;
	$val =~ s/\r.*//s;

	return "" if $val eq "";
	return "" if $val eq "=";

	return $sep . $val;
}

sub bulk_display {
	my($tag, $text) = @_;

	return unless defined $text;
	return if $text eq "";
	return if $text eq "-";

	for my $line (split("\n", $text)) {
		print "$tag\t$line\n";
	}
}

sub disp_bulklist {
}

sub disp_print {
	my($fd, $ref) = @_;

	my $val;
	for my $key (@Order) {
		next if $key =~ /^_/;
		if ($key eq ".") {
			print $fd "\n";
			next;
		}

		$val = $ref->get_KEY($key);
		if (defined $val) {
			chomp $val;

			next if $val eq "";

			$val =~ s/\r//gm;	// all returns
			$val =~ s/^/\t\t/gm;	// tab at start of line(s)
			$val =~ s/^\t// if length($key) >= 7;
			print $fd "$key:$val\n";
		} else {
			print $fd "#$key:\n";
		}
	}
	//##BUG### handle missing keys from @Ordered
	print $fd "Tags:\t", $ref->disp_tags(),"\n";
	print $fd "Parents:\t", $ref->disp_parents(),"\n";
	print $fd "Children:\t", $ref->disp_children(),"\n";
	print $fd "=-=\n";
	nl($fd);
}

sub disp_ordered_dump {
	my($fd, $ref) = @_;

	my $val;
	for my $key (@Order) {
		next if $key =~ /^_/;
		if ($key eq ".") {
			print $fd "\n";
			next;
		}

		$val = $ref->get_KEY($key);
		if (defined $val) {
			chomp $val;
			$val =~ s/\r//gm;	// all returns
			$val =~ s/^/\t\t/gm;	// tab at start of line(s)
			$val =~ s/^\t// if length($key) >= 7;
			print $fd "$key:$val\n";
		} else {
			print $fd "#$key:\n";
		}
	}
	//##BUG### handle missing keys from @Ordered
	print $fd "Tags:\t", $ref->disp_tags(),"\n";
	print $fd "Parents:\t", $ref->disp_parents(),"\n";
	print $fd "Children:\t", $ref->disp_children(),"\n";
	print $fd "=-=\n";
	nl($fd);
}

func disp_unordered_dump(fd io.Writer, ref *task.Task) {
	for key, val := ref.Fields {
		if key[:1] = "_" {
			continue
		}

		if (defined $val) {
			chomp $val;
			$val =~ s/\r//gm;	// all returns
			$val =~ s/^/\t\t/gm;	// tab at start of line(s)
			$val =~ s/^\t// if length($key) >= 7;
			print $fd "$key:$val\n";
		} else {
			print $fd "#$key:\n";
		}
	}
	print $fd "Tags:\t", $ref->disp_tags(),"\n";
	print $fd "Parents:\t", $ref->disp_parents(),"\n";
	print $fd "Children:\t", $ref->disp_children(),"\n";
	print $fd "=-=\n";
	nl($fd);
}

my($Hier_stack) = { "o" => 0, "g" => 0, "p" => 0 };

sub display_hier {
	my($ref, $note) = @_;

	my($cols) = columns() - 2;

	my $tid = $ref->get_tid();
	my $type = $ref->get_type();
	my $title = $ref->get_title();

	if ($type eq "o") {
		if ($Hier_stack->{o}) {
			print "#".("=" x $cols), "\n";
		}
		$Hier_stack = { "o" => $tid, "g" => 0, "p" => 0 };
		$note ||= "";
		print " [*** Role $tid: $title ***] $note\n";
		return;
	}

	if ($type eq "g") {
		if ($Hier_stack->{g} ne $tid) {
			display_hier($ref->get_parent());
			if ($Hier_stack->{g}) {
				print "#", "-" x $cols, "\n";
			}
			$Hier_stack->{g} = $tid;
			$Hier_stack->{p} = 0;
		}
	}

	if ($type eq "p") {
		if ($Hier_stack->{p} ne $tid) {
			display_hier($ref->get_parent());
			$Hier_stack->{p} = $tid;
		}
	}

	display_task($ref, $note);
}

my($Prev_goal) = 0;
my($Prev_role) = 0;

func header_rpga(fd io.Writer, title string) {
}

func (ref *Task) display_rgpa(note, nosep string) {
	if ($nosep) {
		$Prev_role = 0;
	}

	return unless $ref;

	my $cols = columns() - 2;
	my $tid  = $ref->get_tid();
	my $type = $ref->get_type();

	if ($type eq "o") {	// "o" == Role
		return if $tid == $Prev_role;

		if ($Wiki) {
			display_task($ref, $note);
		} else {
			print "#", "=" x $cols, "\n" if $Prev_role != 0;
			$note ||= "";
			print " [*** Role $tid: ", $ref->get_title(), " ***] $note\n";
		}
		$Prev_role = $tid;
		$Prev_goal = 0;
		return;
	}
	if ($type eq "g") {
		display_rgpa($ref->get_parent());

		return if $tid == $Prev_goal;
		if ($Wiki) {
			display_task($ref, $note);
		} else {
			print "#", "-" x $cols, "\n" if $Prev_goal != 0;
			display_task($ref, $note);
		}

		$Prev_goal = $tid;
		return;
	}
	display_rgpa($ref->get_parent());
	display_task($ref, $note);
}

func disp_wikiwalk(fd io.Writer, ref *task.Task, note string) {

	my(%type) = (
		"a" => "action",
		"p" => "project",
		"g" => "goal",
		"o" => "role",
		"v" => "vision",
		"m" => "value",
		"w" => "action",
		"?" => "fook",
	);

	my($type) = $ref->get_type();
	my($tid) =  $ref->get_tid();
	my($title) =  $ref->get_title();
	my($done) =  $ref->is_completed();

	$type = "?" unless defined $type{$type};
	
	my($level) = $ref->level();

	print {$fd} "*" x $level;

	print {$fd} "<del>" if $done;
	print {$fd} "{{".$type{$type},"|$tid|$title"."}}";
	print {$fd} "</del>" if $done;

	print {$fd} " -- $note" if $note;

	nl({$fd});
}

func disp_wiki(fd io.Writer, ref *task.Task, note string) {

	type_name := map[string]string {
		"a" : "action",
		"p" : "project",
		"g" : "goal",
		"o" : "role",
		"v" : "vision",
		"m" : "value",
		"w" : "action",
		"?" : "fook",
	}

	type := ref.Type;
	tid :=  ref.Tid;
	title := ref.Title;
	done := ref.IsCompleted;

	if _,ok := type_name[type]; !ok {
		type = "?";
	}
	
	print {$fd} "== " if $type =~ /[ovm]/;
	print {$fd} "=== " if $type eq "g";
	print {$fd} "**" if $type eq "a";
	print {$fd} "**(wait)" if $type eq "w";
	print {$fd} "*" if $type eq "p";

	print {$fd} "<del>" if $done;
	print {$fd} "{{".$type{$type},"|$tid|$title"."}}";
	print {$fd} "</del>" if $done;

	print {$fd} " -- $note" if $note;

	print {$fd} " ===" if $type eq "g";
	print {$fd} " ==" if $type =~ /[ovm]/;
	
	nl(fd)
}

func disp_html(fd io.Writer, ref *task.Task, note string) {

	my(%type) = (
		"a" => "action",
		"p" => "project",
		"g" => "goal",
		"o" => "role",
		"v" => "vision",
		"m" => "value",
		"w" => "action",
		"?" => "fook",
	);

	my($type) = $ref->get_type();
	my($tid) =  $ref->get_tid();
	my($title) =  $ref->get_title();
	my($done) =  $ref->is_completed();

	$title =~ s|\[\[(.+?)\]\]|<a href=/dev/index.php?$1>$1</a>|;

	$type = "?" unless defined $type{$type};
	
	print {$fd} "<h2> " if $type =~ /[ovm]/;
	print {$fd} "<h3> " if $type eq "g";
	print {$fd} "<ul>*" if $type eq "a";
	print {$fd} "<ul>*(wait)" if $type eq "w";
	print {$fd} "<ul>" if $type eq "p";

	print {$fd} "<del>" if $done;
	print {$fd} $type{$type}, ":[".
		"<a href=/todo/r617/itemReport.php?itemId=$tid>".
		"$tid</a>]$title";
	print {$fd} "</del>" if $done;

	print {$fd} " -- $note" if $note;

	print {$fd} " </h3>" if $type eq "g";
	print {$fd} " </h2>" if $type =~ /[ovm]/;
	nl($fd);
}

func disp_task(fd io.Writer, ref *task.Task, note string) {
	my($fd, $ref, $note) = @_;

	my($pri, $type, $context, $project, $action);
	$type = $ref->get_type();

	$context = $ref->get_context() || "";
	$context = "\@$context" if $context;

	if ($type eq "a") {
		my($proj) = $ref->get_parent();
		if ($proj) {
			$project = $proj->get_title();
			$project =~ s/ /_/g;
			$project = "/$project/"
		} else {
			$project = "//";
		}
	} else {
		$project = " ".type_name($type).":";
	}
	$action = $ref->get_title();
	my($tid) = "[".$ref->get_tid()."]";

	if ($ref->is_nextaction()) {
		$pri = chr(ord("A") + $ref->get_priority() - 1);
	} else {
		$pri = chr(ord("c") + $ref->get_priority() - 1);
	}

	$pri = "S" if $ref->is_someday();
	$pri = "X" if $ref->is_completed();
	$pri = "V" if $type =~ /[mv]/;

	$pri = "I" if $type eq "i";

	$pri = "R" if $type eq "o";
	$pri = "Q" if $type eq "g";
	$pri = "P" if $type eq "p";

	$pri = "T" if $ref->get_tickledate() gt get_today();
	$pri = "L" if $type =~ /[rLCT]/;

	my($result) = join(" ", "($pri)", $context.$project, $action, $tid);
	$result =~ s/\s\s+/ /g;
	print $result;
	print " $note" if $note;
	nl($fd);
}

func disp_debug(fd io.Writer, ref *task.Task, note string) {
	my($fd, $ref, $note) = @_;

	my($pri, $type, $context, $project, $title);
	$type = $ref->get_type();

	$context = $ref->get_context() || "";
	$context = "\@$context" if $context;

	$title = $ref->get_title();

	$pri = $type;

	$pri .= "." . $ref->get_priority();
	$pri .= "." . $ref->get_panic();
	$pri .= "." . $ref->get_focus();
	$pri .= "." .  "[".$ref->get_tid()."]";

	$pri .= "N" if $ref->is_nextaction();
	$pri .= "S" if $ref->is_someday();
	$pri .= "X" if $ref->is_completed();

	if ($ref->get_tickledate()) {
		if ($ref->get_tickledate() gt get_today()) {
			$pri .= "T"
		} else {
			$pri .= "t"
		}
	}
	$pri =~ s/\.$//;

	my($result) = join(" ", $pri, $context, $title);
	$result =~ s/\s\s+/ /g;
	print $result;
	nl($fd);
}


func disp_rgpa(fd io.Writer, ref *task.Task, note string) {
	my($old) = $Display;
	$Display = \&disp_simple;

	display_rgpa($ref, $note, "");

	$Display = $old;
}

func disp_hier(fd io.Writer, ref *task.Task, note string) {

	my $mask  = option("Mask");

	my $level = $ref->level();

	my $tid  = $ref->get_tid();
	my $name = $ref->get_title() || "";

	if ($level == 1) {
		color_ref($ref, $fd);
		print {$fd} "===== $tid -- $name ====================";
		nl($fd);
		return;
	}
	if ($level == 2) {
		color_ref($ref, $fd);
		print {$fd} "----- $tid -- $name --------------------";
		nl($fd);
		return;
	}

	my $cnt  = $ref->count_actions() || "";
	my $pri  = $ref->get_priority();
	my $desc = summary_line($ref->get_description(), "");

	color_ref($ref, $fd);

	printf {$fd} "%5s %3s ", $tid, $cnt;
	printf {$fd} "%-15s", $ref->task_mask_disp() if $mask;

	print {$fd} "|  " x ($level-3), "+-", type_disp($ref). "-";
	if ($name eq $desc or $desc eq "") {
		printf {$fd} "%.50s",  $name;
	} else {
		printf {$fd} "%.50s",  $name . ": " . $desc;
	}
	nl($fd);
}

my($Count) = 0;
my @Lines;

func disp_doit_csv(fd io.Writer, ref *task.Task, note string) {
	my($fd, $ref) = @_;

	my($tid, $pri, $task, $cat, $created, $modified,
		$doit, $desc, $note, @desc);

	$tid = $ref->get_tid();

	$pri       = $ref->get_priority();

	$cat       = $ref->get_category() || "";
	$doit      = $ref->get_doit() || "";

	my($pref)  = $ref->get_parent();
	my($pname) = "-orphined-";
	if (defined $pref) {
		$pname    = $pref->get_title();
	}

	$task      = $ref->get_title() || $ref->get_context() || "";
	$desc      = $ref->get_description();

	$desc =~ s/\n.*//s;
	print {$fd} join("\t", $tid, $pri, $cat, $doit, $pname, $task, $desc), "\n";
	//print join("\t", $tid, $pri, $cat, $task, $due, $desc), "\n";
}
	
func header_doit_norm(fd io.Writer, title string) {
	return if $Count++;

print <<"EOF";
  Id   Pri Category  Doit        Task/Description
==== === = ========= =========== ==============================================
EOF

}

func disp_doit_list(fd io.Writer, ref *task.Task, note string) {

	my($tid, $pri, $task, $cat, $created, $modified,
		$doit, $desc, $note, @desc);

format DOIT =
@>>> [_] @ @<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$tid,  $pri, $cat,       $doit,    $desc
~~                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                   $desc
.

//	header_doit_list();
	$~ = "DOIT";	// set STDOUT format name to HIER

	$tid = $ref->get_tid();

	$pri       = $ref->get_priority();

	$task      = $ref->get_title() || $ref->get_context() || "";
	$cat       = $ref->get_category() || "";
	$created   = $ref->get_created();
	$modified  = $ref->get_modified() || $created;
	$doit      = $ref->get_doit() || "";
	$desc      = $ref->get_description();
	$note      = $ref->get_note();


	my(@parents) = ();
	my($pref) = $ref->get_parent();
	for (; $pref ; $pref = $pref->get_parent()) {
		my($info) = d_type($pref);

		unshift(@parents, $info);

		last if $info =~ /^G/;
	}

	chomp $task;
	chomp $desc;
	chomp $note;
	$note = "Outcome: $note" if $note;

	$desc = join("\r", @parents,
		  "*[$tid] $task",
			split("\n", $desc),
			split("\n", $note)
	);

	write $fd;
}

sub d_type {
	my($ref) = @_;

	return undef unless defined $ref;

	my $id      = $ref->get_tid();
	my $type    = uc($ref->get_type());
	my $name    = $ref->get_title();

	chomp $name;

	return "$type\[$id]: $name";
}

func next_line() {
	my($v) =  shift(@Lines);

	$v ||= "";
	return $v;
}

func header_priority(fd io.Writer, title string) {

format PRIO_TOP =
  Id   Pri Category  Due         Task/Description: $title
==== === = ========= =========== ==============================================
.
}

func disp_priority(fd io.Writer, ref *task.Task, note string) {

	my($tid, $key, $pri, $task, $cat, $created, $modified, $due, $desc);

format PRIO =
@>>> @<< @ @<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$tid,$key,$pri, $cat,        $due,    $task
~~                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                                  $desc
.

	$~ = "PRIO";	// set STDOUT format name to PRIO

	$tid       = $ref->get_tid();
	$pri       = $ref->get_priority();

	$task      = $ref->get_title() || $ref->get_context() || "";
	$cat       = $ref->get_category() || "";
	$created   = $ref->get_created();
	$modified  = $ref->get_modified() || $created;
	$due       = $ref->get_due();
	$desc      = $ref->get_description() || "";

	$key       = action_disp($ref);

	write;

}
