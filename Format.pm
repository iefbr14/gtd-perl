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
		&report_header &count_children &summary_line
		&display_mode &display_fd_task &display_task
		&display_rgpa &display_hier
	);
}

use Hier::util;
use Hier::Option;


my $Display = \&disp_simple;
my $Header  = undef;

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

	my(%mode) = (
		'none'     => \&disp_none,

		'tid'      => \&disp_tid,
		'list'     => \&disp_tid,
		'title'    => \&disp_title,
		'item'     => \&disp_item,
		'simple'   => \&disp_simple,
		'summary'  => \&disp_summary,
		'detail'   => \&disp_detail,

		'task'     => \&disp_task,
		'doit'     => \&disp_task,

		'html'     => \&disp_html,
		'wiki'     => \&disp_wiki,

		'd_csv'    => \&disp_doit_csv,
		'd_lst'    => \&disp_doit_list,

		'rpga'     => \&disp_rgpa,
		'rgpa'     => \&disp_rgpa,
		'hier'     => \&disp_hier,
		'priority' => \&disp_priority,

		'dump'     => \&disp_ordered_dump,

		'udump'    => \&disp_unordered_dump,
		'sdump'    => \&disp_simple_dump,
		'odump'    => \&disp_ordered_dump,
	);

	my(%report) = (
		'none'     => 'none',

		'tid'      => 'report',
		'list'     => 'report',
		'title'    => 'report',
		'item'     => 'report',
		'simple'   => 'report',
		'summary'  => 'report',
		'detail'   => 'report',
		'task'     => 'report',

		'doit'     => 'report',
		'html'     => 'html',
		'wiki'     => 'wiki',

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
		'rgpa'     => \&header_rgpa,
		'hier'     => \&header_hier,
	);

	$mode = 'simple' if $mode eq '';

	if ($mode eq 'simple') {
		$mode = 'tid' if option('List', 0);
	}

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
	&$Header(\*STDOUT, @_);
}

sub count_children {
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

	print {$fd} '#',"=" x $cols, "\n";
	print {$fd} "#== $title\n";
	print {$fd} '#',"=" x $cols, "\n";
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

	print {$fd} $tid, "\n";
}

sub disp_title {
	my($fd, $ref) = @_;

	my($title) = $ref->get_title();

	print {$fd} $title, "\n";
}

sub disp_item {
	my($fd, $ref, $extra) = @_;

	my($tid) = $ref->get_tid();
	my($type) = type_disp($ref);
	my($title) = $ref->get_task();

	my($desc) = format_summary($ref->get_description(), ' -- ');
	print {$fd} "$tid\t  [_] $title$desc\n";
}

sub disp_simple {
	my($fd, $ref, $extra) = @_;

	my($tid) = $ref->get_tid();
	my($type) = type_disp($ref);
	my($title) = $ref->get_task();

	if ($extra) {
		$extra = ' '. $extra;
	} else {
		$extra = '';
	}


	print {$fd} "$tid:\t$type $title$extra\n";
}

sub disp_detail {
	my($fd, $ref, $extra) = @_;

	disp_simple(@_);

	bulk_display('+', $ref->get_description());
	bulk_display('=', $ref->get_note());
	print "\n";
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

sub disp_rpga {
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
	print $fd "=-=\n\n";
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
	print $fd "#Parents:\t", $ref->disp_parents(),"\n";
	print $fd "#Children:\t", $ref->disp_children(),"\n";
	print $fd "=-=\n\n";
}

my($Hier_stack) = { 'o' => 0, 'g' => 0, 'p' => 0 };

sub display_hier {
	my($ref, $counts) = @_;

	my($cols) = columns() - 2;

	my $tid = $ref->get_tid();
	my $type = $ref->get_type();
	my $title = $ref->get_title();

	if ($type eq 'o') {
		if ($Hier_stack->{o}) {
			print '#'.("=" x $cols), "\n";
		}
		$Hier_stack = { 'o' => $tid, 'g' => 0, 'p' => 0 };
		$counts ||= '';
		print " [*** Role $tid: $title ***] $counts\n";
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

	display_task($ref, $counts);
}

my($Prev_goal) = 0;
my($Prev_role) = 0;

sub header_rgpa {
}

sub display_rgpa {
	my($ref, $counts) = @_;

	my($cols) = columns() - 2;

	my $pid = $ref->get_tid();

	my $g_ref = $ref->get_parent();
	my $g_id  = $g_ref->get_tid();

	my $r_ref = $g_ref->get_parent();
	my $r_id  = $r_ref->get_tid();

	#print "$r_id\t$g_id\t$pid\t$Meta_key{$pid}\n";next;

	if ($r_id != $Prev_role) {
		print '#', "=" x $cols, "\n" if $Prev_role != 0;
		print " [*** Role $r_id: ", $r_ref->get_title(), " ***]\n";
#		print '#', "-" x $cols, "\n";

		$Prev_role = $r_id;
		$Prev_goal = 0;
	}

	if ($g_id != $Prev_goal) {
		print '#', "-" x $cols, "\n" if $Prev_goal != 0;
		display_task($g_ref);

		$Prev_goal = $g_id;
	}

	display_task($ref, $counts);
}

sub disp_wiki {
	my($fd, $ref) = @_;

	my(%type) = (
		'a' => 'action',
		'p' => 'project',
		'g' => 'goal',
		'o' => 'role',
		'v' => 'value',
		'm' => 'vision',
		'w' => 'action',
		'?' => 'fook',
	);

	my($type) = $ref->get_type();
	my($tid) =  $ref->get_tid();
	my($title) =  $ref->get_title();
	my($done) =  $ref->get_completed();

	$type = '?' unless defined $type{$type};
	
	print {$fd} '== ' if $type =~ /[govm]/;
	print {$fd} '**' if $type eq 'a';
	print {$fd} '*' if $type eq 'p';

	print {$fd} "<del>" if $done;
	print {$fd} '{{'.$type{$type},"|$tid|$title".'}}';
	print {$fd} "</del>" if $done;

	print {$fd} ' ==' if $type =~ /[govm]/;
	print {$fd} "\n";
}

sub disp_task {
	my($fd, $ref) = @_;

	my($pri, $type, $context, $project, $action);
	$type = $ref->get_type();

	$context = $ref->get_context() || '';
	$context = "\@$context" if $context;

	if ($type eq 'a') {
		my($proj) = $ref->get_parent();
		if ($proj) {
			$project = $proj->get_task();
			$project =~ s/ /_/g;
			$project = "/$project/"
		} else {
		}
	} else {
		$project = ' '.type_name($type).':';
	}
	$action = $ref->get_task();
	my($tid) = '['.$ref->get_tid().']';

	if ($ref->is_nextaction()) {
		$pri = chr(ord('A') + ($ref->get_priority() || '4') - 1);
	} else {
		$pri = chr(ord('C') + ($ref->get_priority() || '4') - 1);
	}

	$pri = 'S' if $ref->get_isSomeday() eq 'y';
	$pri = 'X' if $ref->get_completed();
	$pri = 'V' if $type =~ /[mv]/;
	$pri = 'R' if $type eq 'o';
	$pri = 'I' if $type eq 'i';
	$pri = 'L' if $type =~ /[rLCT]/;


	print join(' ', "($pri)", $context.$project, $action, $tid), "\n";
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

	$task      = $ref->get_task() || $ref->get_context() || '';
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

sub display_doit_list {
	my($ref) = @_;

	my($tid, $pri, $task, $cat, $created, $modified,
		$doit, $desc, $note, @desc);

format DOIT =
@>>> [_] @ @<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$tid,  $pri, $cat,       $doit,    $desc
~~                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                   $desc
.

	header_doit_list();
	$~ = "DOIT";	# set STDOUT format name to HIER

	$tid = $ref->get_tid();

	$pri       = $ref->get_priority();

	$task      = $ref->get_task() || $ref->get_context() || '';
	$cat       = $ref->get_category() || '';
	$created   = $ref->get_created();
	$modified  = $ref->get_modified() || $created;
	$doit      = $ref->get_doit() || '';
	$desc      = $ref->get_description();
	$note      = $ref->get_note();

	my($pid, $pref, $pname, $pdesc);

	$pref     = $ref->get_parent();
	next unless defined $pref;

	$pid      = $pref->get_tid();
	$pname    = $pref->get_title();
	$pdesc    = $pref->get_description();

	my($gid, $gref, $gname);
	$gref      = $pref->get_parent();
	next unless defined $gref;

	$gid      = $gref->get_tid();
	$gname    = $gref->get_title();

	chomp $gname;
	chomp $pname;
	chomp $pdesc;
	chomp $task;
	chomp $desc;
	chomp $note;
	$note = "Outcome: $note" if $note;

	$desc = join("\r", "G[$gid]: $gname",
		  "P[$pid]: $pname", 
			split("\n", $pdesc),
		  "*[$tid] $task",
			split("\n", $desc),
			split("\n", $note)
	);

	write;
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

	$task      = $ref->get_task() || $ref->get_context() || '';
	$cat       = $ref->get_category() || '';
	$created   = $ref->get_created();
	$modified  = $ref->get_modified() || $created;
	$due       = $ref->get_due();
	$desc      = $ref->get_description() || '';

	$key       = action_disp($ref);

	write;

}
1;
