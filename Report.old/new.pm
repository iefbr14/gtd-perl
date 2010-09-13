package Hier::Report::new;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_new);
}

use Hier::globals;
use Hier::Tasks;

sub Report_new {
        my($name) = meta_desc(@ARGV);
        if ($name) {
                my($want) = type_val($name);
		unless ($want) {
			print "**** Can't understand Type $name\n";
			exit 1;
		}
                if (is_hier_type($want)) {
                        new_project($want, $name);
                        return;
                }
                if (is_hier_action($want)) {
                        new_action($want, $name);
                        return;
                }
        }
	new_inbox('i', $name);
}


sub new_inbox {
	my($type, $task) = @_;

	###BUG### make this fast and simple.
	my($pri, $category, $note, $desc, $line);

	my($def_cat) = $Category ? $Category : 'Unfiled';

	print "Enter Task, Priority, Desc, palm Category, Notes...\n";
	print "  enter ^D to stop, entry not added\n";
	print "  use '.' to stop adding notes.\n";
	for (;;) {
		while ($task eq '') {
			$task = prompt("Add Task:     ");
		}
		$pri      =     $Priority || 3;
		$desc     =     prompt("Add Desc:     ");

		print "Palm Category, and notes....\n";
		$category =     prompt("Add Category: ", $def_cat);
		$category ||= $def_cat;
		$line     =     prompt("Add Note:     "); 
		for ($note=''; $line; $line= prompt("+ ")) {
			last if $line eq '.';
			$note .= $line . "\n";
		}
		chomp $note;
		$note = undef if $note eq '';

		my($ref) = gtd_create();

		set($ref, priority    => $pri);
		set($ref, category    => $category);
		set($ref, task        => $task);
		set($ref, description => $desc);
		set($ref, note        => $note);

		set($ref, type => 'a'); # action
		set($ref, nextaction => 'y') if $pri > 3;

		set($ref, isSomeday => 'y') if $pri < 3;
		gtd_insert($ref);
	}
}

sub new_action {
	my($type, $task) = @_;

	my($pri, $category, $note, $desc, $line);

	my($def_cat) = $Category ? $Category : 'Unfiled';

	print "Enter Task, Priority, Desc, palm Category, Notes...\n";
	print "  enter ^D to stop, entry not added\n";
	print "  use '.' to stop adding notes.\n";
	for (;;) {
		while ($task eq '') {
			$task = prompt("Add Task:     ");
		}
		$pri      =     prompt("Add Priority: ", $Priority || 3);
		$desc     =     prompt("Add Desc:     ");

		print "Palm Category, and notes....\n";
		$category =     prompt("Add Category: ", $def_cat);
		$category ||= $def_cat;
		$line     =     prompt("Add Note:     "); 
		for ($note=''; $line; $line= prompt("+ ")) {
			last if $line eq '.';
			$note .= $line . "\n";
		}
		chomp $note;
		$note = undef if $note eq '';

		my($ref) = gtd_create();

		set($ref, priority    => $pri);
		set($ref, category    => $category);
		set($ref, task        => $task);
		set($ref, description => $desc);
		set($ref, note        => $note);

		set($ref, type => 'a'); # action
		set($ref, nextaction => 'y') if $pri > 3;

		set($ref, isSomeday => 'y') if $pri < 3;
		gtd_insert($ref);
	}
}


sub Report_new_project {
	my($type, $name) = @_;

	my($pri, $category, $parent, $desc, $note);

	print "Enter Category, Description, Note...\n";
	print "  enter ^D to stop, entry not added\n";
	for (;;) {
		$category = prompt("Add Category:    ");
		$name     = prompt("Add Name:        ") unless $name;
		$desc     = prompt("Add Description: ");
		$note     = prompt("Add Outcome:     ");

		my($ref) = gtd_create();

		set($ref, category    => $category);
		set($ref, task        => $name);
		set($ref, description => $desc);
		set($ref, note        => $note);

		set($ref, type => $type); 
		gtd_insert($ref);
	}
}

sub prompt {
	my($prompt, $default) = @_;
	local($|) = 1;

	$default ||= '';

	print $prompt;
	if (defined($_ = <STDIN>)) {
		chomp;

		$_ = $default if $_ eq '';

		return $_;
	}
	print "^D -- Bye --\n";
	exit 0;
}

1;  # don't forget to return a true value from the file
