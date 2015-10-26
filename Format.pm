package Hier::Format;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( 
		&report_header &summary_children &summary_line
		&display_mode &display_fd_task &display_task
		&display_rgpa &display_hier
		&disp_ordered_dump
	);
}

use Hier::Util;
use Hier::Option;
use Hier::Color;


my $Display = \&disp_simple;
my $Header  = undef;

my $Wiki = 0;		#### display is in wiki format ####

my @Order = (qw(
	todo_id
	type
	nextaction
	isSomeday
.
	task
	description
	note
.
	category
	context
	timeframe
.
	created
	doit
	modified
	tickledate
	due
	completed
	recur
	recurdesc
.
	owner
	palm_id
	priority
	state
	effort
	resource
	depends
	private
	percent
.
) );
sub display_mode {
	my($mode) = @_;

	my(%alias) = (
		'todo'	=> 'doit',
		'pri'   => 'priority',
	);

	# alias re-mappings
	$mode = lc($mode);
	if (defined $alias{$mode}) {
		$mode = $alias{$mode};
	}

	if ($mode eq 'wiki') {
		$Wiki = 1;
	}

	my(%mode) = (
		'none'     => \&disp_none,
		'list'     => \&disp_title,	# same as title but no headers

		'tid'      => \&disp_tid,
		'title'    => \&disp_title,
		'item'     => \&disp_item,
		'simple'   => \&disp_simple,
		'summary'  => \&disp_summary,
		'detail'   => \&disp_detail,
		'action'   => \&disp_detail,

		'task'     => \&disp_task,
		'doit'     => \&disp_task,

		'html'     => \&disp_html,
		'wiki'     => \&disp_wiki,
		'walk'     => \&disp_wikiwalk,


		'd_csv'    => \&disp_doit_csv,
		'd_lst'    => \&disp_doit_list,

		'rpga'     => \&disp_rgpa,
		'rgpa'     => \&disp_rgpa,
		'hier'     => \&disp_hier,
		'priority' => \&disp_priority,

		'print'    => \&disp_print,

		'dump'     => \&disp_ordered_dump,
		'odump'    => \&disp_ordered_dump,

		'udump'    => \&disp_unordered_dump,
	);

	my(%report) = (
		'none'     => 'none',
		'list'     => 'none',	# same as title but no headers

		'tid'      => 'report',
		'title'    => 'report',
		'item'     => 'report',
		'simple'   => 'report',
		'summary'  => 'report',
		'detail'   => 'report',
		'action'   => 'report',
		'task'     => 'none',

		'doit'     => 'report',
		'html'     => 'html',
		'wiki'     => 'wiki',
		'walk'     => 'wiki',

		'd_csv'    => 'report',
		'd_lst'    => 'report',

		'rpga'     => 'rgpa',
		'rgpa'     => 'rgpa',
		'hier'     => 'hier',
		'priority' => 'report',

		'dump'     => 'none',

		'udump'    => 'none',
		'sdump'    => 'none',
		'odump'    => 'none',
	);
	my(%header) = (
		'none'     => \&header_none,
		'report'   => \&header_report,
		'html'     => \&header_html,
		'wiki'     => \&header_wiki,
		'walk'     => \&header_wiki,
		'rgpa'     => \&header_rgpa,
		'hier'     => \&header_none,
	);

	$mode = 'simple' if $mode eq '';

	# process header modes
	unless (defined $mode{$mode}) {
		warn "Unknown display mode: $mode\n";
		return;
	}

	$Display = $mode{$mode};

	$mode = option('Header', $mode);

	$mode = $report{$mode} if defined $report{$mode};
	$Header = $header{$mode} if defined $header{$mode};
	# pick sorting?
	return;

	
}

#==============================================================================
sub report_header {
	my($title) = option('Title') || '';
	if (@_) {
		my($desc) = join(' ', @_) || '';

		if ($title and $desc) {
			$title .= ' -- ' . $desc;
		} elsif ($title eq '') {
			$title = $desc;
		}
	}

	unless ($Header) {
		display_mode('simple');
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
		$complet++ if $child->get_completed();
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

#==============================================================================
sub display_header {
	&$Header(\*STDOUT, @_);
}

sub header_none {
}

sub header_report {
	my($fd, $title) = @_;
	my($cols) = columns() - 2;

	print {$fd} '#',"=" x $cols; nl($fd);
	print {$fd} "#== $title";    nl($fd);
	print {$fd} '#',"=" x $cols; nl($fd);
}

sub header_wiki {
	my($fd, $title) = @_;

	print {$fd} "== $title ==\n";
}

sub header_html {
	my($fd, $title) = @_;

	print {$fd} "<h1>$title</h1>\n";
}

sub display_task {
	&$Display(\*STDOUT, @_);
}

sub display_fd_task {
	&$Display(@_);
}

sub disp_none {
	# no display
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
	my($fd, $ref, $extra) = @_;

	my($tid) = $ref->get_tid();
	my($type) = type_disp($ref);
	my($title) = $ref->get_title();

	my($desc) = format_summary($ref->get_description(), ' -- ');
	print {$fd} "$tid\t  [_] $title$desc";
	nl($fd);
}

sub disp_simple {
	my($fd, $ref, $extra) = @_;

	my($tid) = $ref->get_tid();
	my($type) = type_disp($ref);
	my($title) = $ref->get_title();

	if ($extra) {
		$extra = ' '. $extra;
	} else {
		$extra = '';
	}


	print {$fd} "$tid:\t$type $title$extra";
	nl($fd);
}

sub disp_detail {
	my($fd, $ref, $extra) = @_;

	disp_simple(@_);

	bulk_display('+', $ref->get_description());
	bulk_display('=', $ref->get_note());
	nl($fd);
}

sub disp_summary {
	my($fd, $ref, $extra) = @_;

	my($desc) = format_summary($ref->get_description(), ' -- ');
	disp_simple(@_, $desc);
}

sub format_summary {
	my($val, $sep, $ishtml) = @_;

	return '' unless $val;
	return '' if $val =~ /^\s*[.\-\*]/;

	$val =~ s/\n.*//s;
	$val =~ s/\r.*//s;

	return '' if $val eq '';
	return '' if $val eq '=';

	return $sep . $val;
}

sub bulk_display {
	my($tag, $text) = @_;

	return unless defined $text;
	return if $text eq '';
	return if $text eq '-';

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
		if ($key eq '.') {
			print $fd "\n";
			next;
		}

		$val = $ref->get_KEY($key);
		if (defined $val) {
			chomp $val;

			next if $val eq '';

			$val =~ s/\r//gm;	# all returns
			$val =~ s/^/\t\t/gm;	# tab at start of line(s)
			$val =~ s/^\t// if length($key) >= 7;
			print $fd "$key:$val\n";
		} else {
			print $fd "#$key:\n";
		}
	}
	###BUG### handle missing keys from @Ordered
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
		if ($key eq '.') {
			print $fd "\n";
			next;
		}

		$val = $ref->get_KEY($key);
		if (defined $val) {
			chomp $val;
			$val =~ s/\r//gm;	# all returns
			$val =~ s/^/\t\t/gm;	# tab at start of line(s)
			$val =~ s/^\t// if length($key) >= 7;
			print $fd "$key:$val\n";
		} else {
			print $fd "#$key:\n";
		}
	}
	###BUG### handle missing keys from @Ordered
	print $fd "Tags:\t", $ref->disp_tags(),"\n";
	print $fd "Parents:\t", $ref->disp_parents(),"\n";
	print $fd "Children:\t", $ref->disp_children(),"\n";
	print $fd "=-=\n";
	nl($fd);
}

sub disp_unordered_dump {
	my($fd, $ref) = @_;

	my $val;
	for my $key (sort keys %$ref) {
		next if $key =~ /^_/;

		$val = $ref->get_KEY($key);
		if (defined $val) {
			chomp $val;
			$val =~ s/\r//gm;	# all returns
			$val =~ s/^/\t\t/gm;	# tab at start of line(s)
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

my($Hier_stack) = { 'o' => 0, 'g' => 0, 'p' => 0 };

sub display_hier {
	my($ref, $note) = @_;

	my($cols) = columns() - 2;

	my $tid = $ref->get_tid();
	my $type = $ref->get_type();
	my $title = $ref->get_title();

	if ($type eq 'o') {
		if ($Hier_stack->{o}) {
			print '#'.("=" x $cols), "\n";
		}
		$Hier_stack = { 'o' => $tid, 'g' => 0, 'p' => 0 };
		$note ||= '';
		print " [*** Role $tid: $title ***] $note\n";
		return;
	}

	if ($type eq 'g') {
		if ($Hier_stack->{g} ne $tid) {
			display_hier($ref->get_parent());
			if ($Hier_stack->{g}) {
				print '#', "-" x $cols, "\n";
			}
			$Hier_stack->{g} = $tid;
			$Hier_stack->{p} = 0;
		}
	}

	if ($type eq 'p') {
		if ($Hier_stack->{p} ne $tid) {
			display_hier($ref->get_parent());
			$Hier_stack->{p} = $tid;
		}
	}

	display_task($ref, $note);
}

my($Prev_goal) = 0;
my($Prev_role) = 0;

sub header_rgpa {
}

sub display_rgpa {
	my($ref, $note, $nosep) = @_;
	if ($nosep) {
		$Prev_role = 0;
	}

	return unless $ref;

	my $cols = columns() - 2;
	my $tid  = $ref->get_tid();
	my $type = $ref->get_type();

	if ($type eq 'o') {	# 'o' == Role
		return if $tid == $Prev_role;

		if ($Wiki) {
			display_task($ref, $note);
		} else {
			print '#', "=" x $cols, "\n" if $Prev_role != 0;
			$note ||= '';
			print " [*** Role $tid: ", $ref->get_title(), " ***] $note\n";
		}
		$Prev_role = $tid;
		$Prev_goal = 0;
		return;
	}
	if ($type eq 'g') {
		display_rgpa($ref->get_parent());

		return if $tid == $Prev_goal;
		if ($Wiki) {
			display_task($ref, $note);
		} else {
			print '#', "-" x $cols, "\n" if $Prev_goal != 0;
			display_task($ref, $note);
		}

		$Prev_goal = $tid;
		return;
	}
	display_rgpa($ref->get_parent());
	display_task($ref, $note);
}

sub disp_wikiwalk {
	my($fd, $ref, $note) = @_;

	my(%type) = (
		'a' => 'action',
		'p' => 'project',
		'g' => 'goal',
		'o' => 'role',
		'v' => 'vision',
		'm' => 'value',
		'w' => 'action',
		'?' => 'fook',
	);

	my($type) = $ref->get_type();
	my($tid) =  $ref->get_tid();
	my($title) =  $ref->get_title();
	my($done) =  $ref->get_completed();

	$type = '?' unless defined $type{$type};
	
	my($level) = $ref->level();

	print {$fd} '*' x $level;

	print {$fd} "<del>" if $done;
	print {$fd} '{{'.$type{$type},"|$tid|$title".'}}';
	print {$fd} "</del>" if $done;

	print {$fd} " -- $note" if $note;

	nl({$fd});
}

sub disp_wiki {
	my($fd, $ref, $note) = @_;

	my(%type) = (
		'a' => 'action',
		'p' => 'project',
		'g' => 'goal',
		'o' => 'role',
		'v' => 'vision',
		'm' => 'value',
		'w' => 'action',
		'?' => 'fook',
	);

	my($type) = $ref->get_type();
	my($tid) =  $ref->get_tid();
	my($title) =  $ref->get_title();
	my($done) =  $ref->get_completed();

	$type = '?' unless defined $type{$type};
	
	print {$fd} '== ' if $type =~ /[ovm]/;
	print {$fd} '=== ' if $type eq 'g';
	print {$fd} '**' if $type eq 'a';
	print {$fd} '**(wait)' if $type eq 'w';
	print {$fd} '*' if $type eq 'p';

	print {$fd} "<del>" if $done;
	print {$fd} '{{'.$type{$type},"|$tid|$title".'}}';
	print {$fd} "</del>" if $done;

	print {$fd} " -- $note" if $note;

	print {$fd} ' ===' if $type eq 'g';
	print {$fd} ' ==' if $type =~ /[ovm]/;
	nl($fd);
}

sub disp_html {
	my($fd, $ref, $note) = @_;

	my(%type) = (
		'a' => 'action',
		'p' => 'project',
		'g' => 'goal',
		'o' => 'role',
		'v' => 'vision',
		'm' => 'value',
		'w' => 'action',
		'?' => 'fook',
	);

	my($type) = $ref->get_type();
	my($tid) =  $ref->get_tid();
	my($title) =  $ref->get_title();
	my($done) =  $ref->get_completed();

	$title =~ s|\[\[(.+?)\]\]|<a href=/dev/index.php?$1>$1</a>|;

	$type = '?' unless defined $type{$type};
	
	print {$fd} '<h2> ' if $type =~ /[ovm]/;
	print {$fd} '<h3> ' if $type eq 'g';
	print {$fd} '<ul>*' if $type eq 'a';
	print {$fd} '<ul>*(wait)' if $type eq 'w';
	print {$fd} '<ul>' if $type eq 'p';

	print {$fd} "<del>" if $done;
	print {$fd} $type{$type}, ":[".
		"<a href=/todo/r617/itemReport.php?itemId=$tid>".
		"$tid</a>]$title";
	print {$fd} "</del>" if $done;

	print {$fd} " -- $note" if $note;

	print {$fd} ' </h3>' if $type eq 'g';
	print {$fd} ' </h2>' if $type =~ /[ovm]/;
	nl($fd);
}

sub disp_task {
	my($fd, $ref, $note) = @_;

	my($pri, $type, $context, $project, $action);
	$type = $ref->get_type();

	$context = $ref->get_context() || '';
	$context = "\@$context" if $context;

	if ($type eq 'a') {
		my($proj) = $ref->get_parent();
		if ($proj) {
			$project = $proj->get_title();
			$project =~ s/ /_/g;
			$project = "/$project/"
		} else {
			$project = "//";
		}
	} else {
		$project = ' '.type_name($type).':';
	}
	$action = $ref->get_title();
	my($tid) = '['.$ref->get_tid().']';

	if ($ref->is_nextaction()) {
		$pri = chr(ord('A') + $ref->get_priority() - 1);
	} else {
		$pri = chr(ord('c') + $ref->get_priority() - 1);
	}

	$pri = 'S' if $ref->is_someday() eq 'y';
	$pri = 'X' if $ref->get_completed();
	$pri = 'V' if $type =~ /[mv]/;

	$pri = 'I' if $type eq 'i';

	$pri = 'R' if $type eq 'o';
	$pri = 'Q' if $type eq 'g';
	$pri = 'P' if $type eq 'p';

	$pri = 'T' if $ref->get_tickledate() gt get_today();
	$pri = 'L' if $type =~ /[rLCT]/;

	my($result) = join(' ', "($pri)", $context.$project, $action, $tid);
	$result =~ s/\s\s+/ /g;
	print $result;
	print " $note" if $note;
	nl($fd);
}

sub disp_rgpa {
	my($fd, $ref, $extra) = @_;

	my($old) = $Display;
	$Display = \&disp_simple;

	display_rgpa($ref, $extra, '');

	$Display = $old;
}

sub disp_hier {
	my($fd, $ref) = @_;

	my $mask  = option('Mask');

	my $level = $ref->level();

	my $tid  = $ref->get_tid();
	my $name = $ref->get_title() || '';

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

	my $cnt  = $ref->count_actions() || '';
	my $pri  = $ref->get_priority();
	my $desc = summary_line($ref->get_description(), '');
	my $done = $ref->get_completed() || '';

	color_ref($ref, $fd);

	printf {$fd} "%5s %3s ", $tid, $cnt;
	printf {$fd} "%-15s", $ref->task_mask_disp() if $mask;

	print {$fd} "|  " x ($level-3), '+-', type_disp($ref). '-';
	if ($name eq $desc or $desc eq '') {
		printf {$fd} "%.50s",  $name;
	} else {
		printf {$fd} "%.50s",  $name . ': ' . $desc;
	}
	nl($fd);
}

my($Count) = 0;
my @Lines;

sub disp_doit_csv {
	my($fd, $ref) = @_;

	my($tid, $pri, $task, $cat, $created, $modified,
		$doit, $desc, $note, @desc);

	$tid = $ref->get_tid();

	$pri       = $ref->get_priority();

	$cat       = $ref->get_category() || '';
	$doit      = $ref->get_doit() || '';

	my($pref)  = $ref->get_parent();
	my($pname) = '-orphined-';
	if (defined $pref) {
		$pname    = $pref->get_title();
	}

	$task      = $ref->get_title() || $ref->get_context() || '';
	$desc      = $ref->get_description();

	$desc =~ s/\n.*//s;
	print {$fd} join("\t", $tid, $pri, $cat, $doit, $pname, $task, $desc), "\n";
	#print join("\t", $tid, $pri, $cat, $task, $due, $desc), "\n";
}
	
sub header_doit_norm {
	return if $Count++;

print <<"EOF";
  Id   Pri Category  Doit        Task/Description
==== === = ========= =========== ==============================================
EOF

}

sub disp_doit_list {
	my($fd, $ref) = @_;

	my($tid, $pri, $task, $cat, $created, $modified,
		$doit, $desc, $note, @desc);

format DOIT =
@>>> [_] @ @<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$tid,  $pri, $cat,       $doit,    $desc
~~                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                   $desc
.

#	header_doit_list();
	$~ = "DOIT";	# set STDOUT format name to HIER

	$tid = $ref->get_tid();

	$pri       = $ref->get_priority();

	$task      = $ref->get_title() || $ref->get_context() || '';
	$cat       = $ref->get_category() || '';
	$created   = $ref->get_created();
	$modified  = $ref->get_modified() || $created;
	$doit      = $ref->get_doit() || '';
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

sub next_line {
	my($v) =  shift(@Lines);

	$v ||= '';
	return $v;
}

sub header_priority {
	my($fd, $title) = @_;

format PRIO_TOP =
  Id   Pri Category  Due         Task/Description: $title
==== === = ========= =========== ==============================================
.
}

sub disp_priority {
	my($fd, $ref) = @_;

	my($tid, $key, $pri, $task, $cat, $created, $modified, $due, $desc);

format PRIO =
@>>> @<< @ @<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$tid,$key,$pri, $cat,        $due,    $task
~~                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                                  $desc
.

	$~ = "PRIO";	# set STDOUT format name to PRIO

	$tid       = $ref->get_tid();
	$pri       = $ref->get_priority();

	$task      = $ref->get_title() || $ref->get_context() || '';
	$cat       = $ref->get_category() || '';
	$created   = $ref->get_created();
	$modified  = $ref->get_modified() || $created;
	$due       = $ref->get_due();
	$desc      = $ref->get_description() || '';

	$key       = action_disp($ref);

	write;

}
1;
