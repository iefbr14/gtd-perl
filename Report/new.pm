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

use Hier::Tasks;
use Hier::util;

my $Category;

sub Report_new {	#-- create a new action or project
        my($name) = shift @ARGV;
        my($title) = meta_desc(@ARGV);

        if ($name) {
                my($want) = type_val($name);
		unless ($want) {
			print "**** Can't understand Type $name\n";
			exit 1;
		}
                if (is_type_hier($want)) {
                        new_project($want, $name, $title);
                        return;
                }
                if (is_type_action($want)) {
                        new_action($want, $name, $title);
                        return;
                }
		print "**** Don't know how to create $name\n";
		print "Creating an inbox item\n";
        }
	new_inbox('i', join(' ', $name, $title));
}

sub is_type_hier {
	my($type) = @_;

	return 1 if $type =~ /^[mvogp]/;
	return 0;
}

sub is_type_action {
	my($type) = @_;

	return 1 if $type =~ /^[awi]/;
	return 0;
}


sub new_inbox {
	my($type, $task, $title) = @_;

	###BUG### make this fast and simple.
	my($pri, $category, $note, $desc, $line);

	print "Enter Task, Priority, Desc, palm Category, Notes...\n";
	print "  enter ^D to stop, entry not added\n";
	print "  use '.' to stop adding notes.\n";
	for (;;) {
		while ($task eq '') {
			$task = prompt("Add Task:     ");
		}
		$pri      =     option('Priority') || 3;
		$desc     =     prompt("Add Desc:     ");

		print "Palm Category, and notes....\n";
		$category =     prompt("Add Category: ", option('Category'));
		$line     =     prompt("Add Note:     "); 
		for ($note=''; $line; $line= prompt("+ ")) {
			last if $line eq '.';
			$note .= $line . "\n";
		}
		chomp $note;

		my $ref = Hier::Tasks->new(undef);

		$ref->set_priority($pri);
		$ref->set_category($category);
		$ref->set_title($task);
		$ref->set_description($desc);
		$ref->set_note($note);

		$ref->set_type('a'); # action
		$ref->set_nextaction('y') if $pri > 3;

		$ref->set_isSomeday('y') if $pri < 3;

		$ref->insert();

		print "Created: ", $ref->get_tid(), "\n";
	}
}

sub new_action {
	my($type, $task) = @_;

	my($pri, $category, $note, $desc, $line);

	print "Enter Task, Priority, Desc, palm Category, Notes...\n";
	print "  enter ^D to stop, entry not added\n";
	print "  use '.' to stop adding notes.\n";
	for (;;) {
		while ($task eq '') {
			$task = prompt("Add Task:     ");
		}
		$pri      =     prompt("Add Priority: ", option('Priority') || 3);
		$desc     =     prompt("Add Desc:     ");

		print "Palm Category, and notes....\n";
		$category =     prompt("Add Category: ", option('Category'));
		$line     =     prompt("Add Note:     "); 
		for ($note=''; $line; $line= prompt("+ ")) {
			last if $line eq '.';
			$note .= $line . "\n";
		}
		chomp $note;

		my $ref = Hier::Tasks->new(undef);

		$ref->set_type('a'); # action

		$ref->set_priority($pri);
		$ref->set_category($category);
		$ref->set_title($task);
		$ref->set_description($desc);
		$ref->set_note($note);

		$ref->set_nextaction('y') if $pri > 3;

		$ref->set_isSomeday('y') if $pri < 3;

		$ref->insert();

		print "Created: ", $ref->get_tid(), "\n";
	}
}


sub new_project {
	my($type, $name, $title) = @_;

	my($pri, $category, $parent, $desc, $note);

	print "Enter $name Category, Description, Outcome...\n";
	print "  enter ^D to stop, entry not added\n";
	for (;;) {
		$category = prompt("Add Category:    ", option('Category'));
		$title    = prompt("Add Title:       ") unless $title;
		$desc     = prompt("Add Description: ");
		$note     = prompt("Add Outcome:     ");

		my $ref = Hier::Tasks->new(undef);

		$ref->set_type($type); 

		$ref->set_category($category);
		$ref->set_title($name);
		$ref->set_description($desc);
		$ref->set_note($note);

		$ref->insert();

		print "Created: ", $ref->get_tid(), "\n";
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
