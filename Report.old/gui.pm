package Hier::Report::gui;

use strict;
use warnings;

use ss::tk::menu;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_gui);
}


use Tk;
use Tk::Tree;

use Hier::globals;
use Hier::walk;
use Hier::util;
use Hier::Report::report;
use Hier::Tasks;

my $Load_Project = 1;
my $Load_Someday = 0;
my $Load_Waiting = 0;
my $Load_Childless = 1;
my $Load_Next_Actions = 1;
my $Load_Actions = 1;
my $Load_Completed = 0;

my $Visable_Roles = 1;
my $Visable_Goals = 1;
my $Visable_Projects = 1;
my $Visable_Someday = 0;
my $Visable_Waiting = 0;
my $Visable_Next_Actions = 0;
my $Visable_Actions = 0;
my $Visable_Completed = 0;

sub Report_gui {	#-- Tk gui front end
	init();
	&Tk::MainLoop();
}

sub init {
        my($file) = @_;
        my($pkg) = {}; bless $pkg;

        my($w) = MainWindow->new();
        $pkg->{-mainWin} = $w;

#	$w->minsize(qw(200 200));
	$w->title("GTD");
	$w->configure(-background => 'cyan');

	my(@reports);
	foreach my $report (get_reports()) {
		push(@reports, $report, sub { &run_report($report) } );
	}
	
	Menu($pkg, $w,
                "File", [
                        "Connect",              \&connect,
                        '-',
                        "Print",                \&print,
                        '-',
                        "Close",                \&ss::list::close,
                ],
		"Include", [
                        "Refresh",              [ \&walk_tree, $pkg ],
			'-',
			"Childless",	\$Load_Childless,
			"Projects",	\$Load_Project,
			"Somedays",	\$Load_Someday,
			"Waiting",	\$Load_Waiting,
			"Next-Actions",	\$Load_Next_Actions,
			"Actions",	\$Load_Actions,
			"Completed",	\$Load_Completed,
		],
		"Visable", [
                        "Refresh",              [ \&walk_tree, $pkg ],
			'-',
			"Roles",	\$Visable_Roles,
			"Goals",	\$Visable_Goals,
			"Projects",	\$Visable_Projects,
			"Somedays",	\$Visable_Someday,
			"Waiting",	\$Visable_Waiting,
			"Next-Actions",	\$Visable_Next_Actions,
			"Actions",	\$Visable_Actions,
			"Completed",	\$Visable_Completed,
		],
		"Reports", \@reports,
                "Quit", \&exit,
                "Help", [
                        "View HTML",    \&none,
                ],
        );

	my $tree;
	$tree = $w->Scrolled('Tree', 
		-scrollbars => "osoe", 	# Onlyneeded South and Onlyneeded East
		-width => 80,
		-height => 40,
	)->pack(
		-fill => 'both',
		-expand => 1,
	);

	$tree->configure(-command => sub { hier_edit($tree, @_) });

	my($walk) = walk();
	$walk->{detail} = \&tk_detail;
	$walk->{tree} = $tree;
	$walk->{done} = $tree;

	$pkg->{walk} = $walk;

	
	$walk->walk();
	walk_tree($pkg);
}

sub walk_tree {
	my($pkg) = @_;
	my($walk) = $pkg->{walk};
	my($tree) = $walk->{tree};

	$tree->delete('all');
	my(%Keys) = %Task;
	for my $tid (grep {
	    is_ref_hier($Keys{$_}) && $Keys{$_}->{type} eq 'm' } keys %Keys) {
		$walk->{path} = '';
		tk_detail(\%Keys, $tid, $Keys{$tid}, $walk);
#		slice(\%Keys, $Keys{$tid}, $walk);
		#old_dice(\%Keys, 0, $tid);
	}

	$tree->autosetmode;
        return $pkg;
}

use Tk::Text;
sub tk_detail {
	my($all, $tid, $ref, $walk) = @_;
	my($sid, $name, $cnt, $desc, $pri, $type, $done, $someday);

	my (%opt);

	return if $tid eq 'lost';
	return if $tid eq 'orphin';

	my $level = $walk->{level};
	my $tree = $walk->{tree};

	$name = $ref->{task} || '';
	$cnt  = $ref->{_actions} || '';
	$pri  = $ref->{priority} || 3;
	$desc = summary_line($ref->{description}, '');
	$type = $ref->{type} || '';
	$done = $ref->{completed} || '';

	$someday = $ref->{isSomeday} || '';

	my($ppath) = $walk->{path};
	my($pdesc,$path, $ptext);

	if ($type eq 'a') {
		$opt{-background} = 'gray',
	} elsif ($type eq 'n') {
		$opt{-background} = 'cyan',
	} elsif ($type eq 'p') {
		$opt{-foreground} = 'pink',
	}

	if ($Load_Completed && $done) {
		# Don't do completed items
	} elsif ($Load_Childless == 0 && $ref->{_actions} == 0 && $ref->{_child} == 0) {
		# Don't do hier items with no children
	} elsif ($Load_Project == 0 && $type eq 'p') {
		# Don't do project 
	} elsif ($Load_Next_Actions == 0 && $type eq 'n') {
		# Don't
	} elsif ($Load_Actions == 0 && $type eq 'a') {
		# Don't 
	} elsif ($Load_Someday == 0 && $someday) {
		# Don't do someday unless -A
		delete $all->{$tid};
		return;
	} else {
		$pdesc = $name; $pdesc =~ s/[^a-zA-Z]/_/g;
		$path = $ppath . '.' . $pdesc . '_' . $tid;

		$ptext .= sprintf "%5s %3s ", $tid, $cnt;

		if (is_ref_hier($ref)) {
			$ptext .= "-($type)-";
		} 

		if ($name eq $desc or $desc eq '') {
			$ptext .= $name;
		} else {
			$ptext .= "$name: $desc";
		}
#		my($text) = tree->Text($ptext, -forground => 'pink');
		$path =~ s/^\.//;
		$tree->add($path, 
			-text => $ptext, 
			-data => $ref,
		);
#		$tree->configure(-background => 'cyan');
	}

	if (is_ref_hier($ref)) {
		$walk->{level}++;
		$walk->{path} = $path;
		slice($all, $ref, $walk);
		$walk->{path} = $ppath;
		$walk->{level}--;
	} else {
		# todo item (no children)
		delete $all->{$tid};
	}
}

sub connect {
}

sub hier_edit {
	
        my($tree, $path) = @_;

	my($ref) = $tree->infoData($path);
	my($tid) = $ref->{todo_id};
print "Edit: $path => $tid\n";

        my($pkg) = {}; bless $pkg;

        my($w) = MainWindow->new();
        $pkg->{-mainWin} = $w;

#	$w->minsize(qw(200 200));
	$path =~ s/_\d+\./:/g;

	$w->title("GTD item $tid => $path");
	$w->configure(-background => 'cyan');

	Menu($pkg, $w,
                "Item", [
                        "Close",             \&connect,
                        "Abadon",            \&connect,
                        "Update",            \&connect,
                        "Save",              \&connect,
                        '-',
                        "Delete",            \&connect,
                        '-',
                        "Print",             \&print,
                ],
                "Help", [
                        "View HTML",    \&none,
                ],
        );

	my($t);
        $pkg->{-textWin} = $t = $w->Scrolled('Text',
                -width => 80,
                -height => 20,
        )->pack;
        $t->bind("<KeyPress>", [\&html_text::key, Ev('A')]);

        # Fill the textbox with a list of all the files in the directory.

        $t->bind('<Button-3>' => sub {
                my($l) = @_;

                print "button-3: l=$l\n";
                $pkg->view;
            }
        );

	my($val);
	foreach my $key (sort keys %$ref) {
		next if $key =~ /^_/;

		$val = $ref->{$key};
		next unless defined $val;

		$val =~ s/\r/\n/g;

		 $t->insert('insert', "$key\t\t$ref->{$key}\n");
	}
	$t->see("insert");

}

sub  run_report {
	my($arg) = @_;


	$arg =~ m/^(\w+)\s+--\s(.)*$/;
	my($report, $title) = ($1, $2);
print "Run: $report\n";

	eval "use Hier::Report::$report";
	if($@) {
		print "Report compile failed: $@\n";
		return;
	}
	my($pid);
	$pid = open(REPORT, '-|');
	if ($pid == 0) {
		#### In child, do NOT use Tk's override exit ####
		eval "Report_$report();";	# call report with argv
		if($@) {
			warn "Report failed: $@\n";
			CORE::exit 1;
		}
		CORE::exit 0;
		#### End child use Tk's override exit ####
	}
        my($file) = @_;
        my($pkg) = {}; bless $pkg;

        my($w) = MainWindow->new();
        $pkg->{-mainWin} = $w;

	$w->title($title);

	Menu($pkg, $w,
                "File", [
                        "Save as...",           \&report_save,
                        '-',
                        "Print",                \&print,
                        '-',
                        "Close",                \&ss::list::close,
                ],
                "Help", [
                        "View HTML",    \&none,
                ],
        );

        # Create a scrollbar on the right side of the
        # main window and a textbox on the left side.

	my $t;

        $pkg->{-textWin} = $t = $w->Scrolled('Text',
                -width => 80,
                -height => 30,
        )->pack();
        $t->bind("<KeyPress>", [\&html_text::key, Ev('A')]);

        # Fill the textbox with a list of all the files in the directory.

	while(<REPORT>) {
		 $t->insert('insert', $_);
	}
	$t->see("insert");

        return $pkg;
}

1;  # don't forget to return a true value from the file
