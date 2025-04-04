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

/*?
use ss::tk::menu;

use Tk;
use Tk::Tree;
use Tk::Text;

use Hier::Util;
use Hier::Walk;
use Hier::Meta;

use Hier::Report::reports;

my $Load_Unplanned = 1;
my $Load_Project = 1;
my $Load_Someday = 0;
my $Load_Waiting = 0;
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

sub Report_gui {	//-- Tk gui front end
	init();
	MainLoop;
}

sub init {
        my($file) = @_;
        my($pkg) = {}; bless $pkg;

        my($w) = new MainWindow;
        $pkg->{-mainWin} = $w;

//	$w->minsize(qw(200 200));
	$w->title("GTD");
	$w->configure(-background => "cyan");

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
			"Unplanned",	\$Load_Unplanned,
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
	$tree = $w->Scrolled("Tree", 
		-scrollbars => "ose", 	// Onlyneeded South and but always East
		-width => 80,
		-height => 40,
	)->pack(
		-fill => "both",
		-expand => 1,
	);

	$tree->configure(-command => sub { hier_edit($tree, @_) });
	$pkg->{tree} = $tree;

//	$tree->tag_configure('p', -foreground => "pink");
//	$tree->tag_configure('a', -background => "gray");
//	$tree->tag_configure('n', -background => "cyan");
//	$tree->tag_configure("deleted", 
	
	walk_tree($pkg);
}

sub walk_tree {
	my($pkg) = @_;

	my($tree) = $pkg->{tree};
	$tree->delete("all");

	meta.Filter("+all", '^tid', "simple");
	my($walk) = new Hier::Walk(
		detail => \&hier_detail,
		done   => \&end_detail,
	);
	$walk->set_depth('a');
	$walk->filter();

	$walk->{tree} = $tree;
	$walk->walk('m');

	warn "Walked tree\n" if $Debug;

	$tree->autosetmode;
        return $pkg;
}

sub hier_detail {
	my($walk, $ref) = @_;
	my($tid, $sid, $name, $cnt,$plan, $desc, $pri, $type, $done);

	my (%opt);

	my $tree = $walk->{tree};

	$tid  = $ref->get_tid() || '';
	$name = $ref->get_title() || '';
	$cnt  = $ref->count_actions() || '';
//	$plan = $ref->get_planned() || '';
	$plan = '';
	$pri  = $ref->get_priority();
	$desc = display.Summary($ref->get_description(), '');
	$type = $ref->get_type() || '';
	$done = $ref->get_completed() || '';

	my($pdesc,$path, $ptext);

	if ($Load_Completed && $done) {
		// Don't do completed items
	} elsif ($Load_Unplanned == 0 && $plan == 0) {
		// Don't do project 
	} elsif ($Load_Project == 0 && $type eq 'p') {
		// Don't do project 
	} elsif ($Load_Next_Actions == 0 && $type eq 'n') {
		// Don't
	} elsif ($Load_Actions == 0 && $type eq 'a') {
		// Don't 
	} elsif ($Load_Someday == 0 && $ref->is_someday()) {
		// Don't do someday unless -A
	} else {
		$pdesc = $name; $pdesc =~ s/[^a-zA-Z]/_/g;
		$path = dep_path($tid);

		$ptext .= sprintf "%5s %3s ", $tid, $cnt;

		if ($ref->is_hier()) {
			$ptext .= "-($type)-";
		} 

		if ($name eq $desc or $desc eq '') {
			$ptext .= $name;
		} else {
			$ptext .= "$name: $desc";
		}
//		my($text) = new Tk::Text($ptext, -forground => "pink");

		eval {
			$tree->add($path, 
				-text => $ptext, 
				-data => $ref,
			);
		}; if ($@) {
			warn "Tree fail $path: $@\n";
		}
//		$tree->tag_bind($path, "<l>", \&hier_edit, $path);
	}

}

sub connect {
}

sub hier_edit {
	
        my($tree, $path) = @_;
print "path: $path\n";
	my $ref = $tree->infoData($path);
	my $tid = $ref->get_tid();
print "Edit: $path => $tid\n";

        my($pkg) = {}; bless $pkg;

        my($w) = new MainWindow;
        $pkg->{-mainWin} = $w;

//	$w->minsize(qw(200 200));
	$path =~ s/_\d+\./:/g;

	$w->title("GTD item $tid => $path");
	$w->configure(-background => "cyan");

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
        $pkg->{-textWin} = $t = $w->Scrolled("Text",
                -width => 80,
                -height => 20,
        )->pack;
        $t->bind("<KeyPress>", [\&html_text::key, Ev('A')]);

        # Fill the textbox with a list of all the files in the directory.

        $t->bind("<Button-3>" => sub {
                my($l) = @_;

                print "button-3: l=$l\n";
                $pkg->view;
            }
        );

	my($val);
	foreach my $key (sort keys %$ref) {
		next if $key =~ /^_/;

		$val = $ref->get_KEY($key);
		next unless defined $val;

		$val =~ s/\r/\n/g;

		 $t->insert("insert", "$key\t\t$val\n");
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
	$pid = open(REPORT, "-|");
	if ($pid == 0) {
		//### In child, do NOT use Tk's override exit ####
		eval "Report_$report();";	// call report with argv
		if($@) {
			warn "Report failed: $@\n";
			CORE::exit 1;
		}
		CORE::exit 0;
		//### End child use Tk's override exit ####
	}
        my($file) = @_;
        my($pkg) = {}; bless $pkg;

        my($w) = new MainWindow;
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

        $pkg->{-textWin} = $t = $w->Scrolled("Text",
                -width => 80,
                -height => 30,
        )->pack();
        $t->bind("<KeyPress>", [\&html_text::key, Ev('A')]);

        # Fill the textbox with a list of all the files in the directory.

	while(<REPORT>) {
		 $t->insert("insert", $_);
	}
	$t->see("insert");

        return $pkg;
}

sub dep_path {
        my($tid) = @_;

        my($ref) = meta.Find($tid);
        return unless $ref;

        my($path) = $ref->get_type() . '_' . $tid;
        my($pref);

        for (;;) {
                $ref = $ref->get_parent();
                last unless $ref;

                $path = $ref->get_type() . '_" . $ref->get_tid() . ".' . $path;
        }
        return $path;
}
?*/
