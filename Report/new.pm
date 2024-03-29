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

use Hier::Meta;
use Hier::Tasks;
use Hier::util;
use Hier::Option;

my $First = '';


#
# there are two paths here.  The first is the command line
# where everything is on the command line and is a one shot
# the other is the prompter version with defaults
#
sub Report_new {	#-- create a new action or project
	unless (@ARGV) {
		new_inbox('i', meta_desc(@ARGV));
		return;
	}
		
        my($type) = shift @ARGV;
	my($name) = '';

	my($want) = type_val($type);
	# prompt path
        if ($want) {
		$name = shift @ARGV if @ARGV;
	} else {
		$name = $want;
		$want = 'i';
	}

	# command line path
	if (@ARGV) {
		new_task('i', $name, meta_desc(@ARGV));
		return;
	}

	my($title) = meta_desc(@ARGV);

	print "new: type=$type($want) name=$name title=$title\n";

	if (is_type_hier($want)) {
		new_project($want, $name, $title);
		return;
	}
	if ($want eq 'i') {
		new_inbox('i', $name, $title);
		return;
	}
	if (is_type_action($want)) {
		new_action($want, $name, $title);
		return;
	} 
	die "Can't happen, don't know how to handle request\n";
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


# command line version
sub new_task {
	my($type, $task, $title) = @_;

	my($pri, $category, $note, $desc, $line);

	$task     = option("Task") || $task;
	$pri      = option('Priority') || 3;
	$desc     = option("Title") || $title;

	$category = option('Category') || '';
	$note     = option('Note'); 

	my $ref = Hier::Tasks->new(undef);

	$ref->set_priority($pri);
	$ref->set_category($category);
	$ref->set_title($task);
	$ref->set_description($desc);
	$ref->set_note($note);

	$ref->set_type($type);

	$ref->set_nextaction('y') if $pri < 3;
	$ref->set_isSomeday('y') if $pri > 3;

	$ref->insert();

	print "Created: ", $ref->get_tid(), "\n";
}

sub new_inbox {
	my($type, $task, $title) = @_;

	###BUG### make this fast and simple.
	my($pri, $category, $note, $desc, $line);

	first("Enter Item, Desc, Category, Notes...");
	for (;;) {
		$task     = prompt("Task", $task);
		$pri      = option('Priority') || 3;
		$desc     = prompts("Desc", $title);

		$category = prompt("Category", option('Category'));
		$note     = prompts("Note", option('Note')); 

		my $ref = Hier::Tasks->new(undef);

		$ref->set_priority($pri);
		$ref->set_category($category);
		$ref->set_title($task);
		$ref->set_description($desc);
		$ref->set_note($note);

		$ref->set_type($type);
		$ref->set_nextaction('y') if $pri > 3;

		$ref->set_isSomeday('y') if $pri < 3;

		$ref->insert();

		print "Created: ", $ref->get_tid(), "\n";
	}
}

sub new_action {
	my($type, $task, $desc) = @_;

	my($pri, $category, $note, $line);

	first("Enter Action, Priority, Desc, palm Category, Notes...");

	for (;;) {
		$task     = prompt("Task", $task);
		$pri      = prompt("Priority", option('Priority')) || 3;
		$desc     = prompts("Desc", $desc);

		$category = prompt("Category", option('Category'));
		$note     = prompts("Note", option('Note')); 

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
	my($type, $title, $desc) = @_;

	my($pri, $category, $parent, $note);

	my($type_name) = type_name($type);

	first("Enter $type_name, Category, Description, Outcome...");

	for (;;) {
		$category = prompt("Category", option('Category'));
		$title    = prompt("Title", $title);
		$pri      = option('Priority') || 3;
		if ($desc) {
			$note = option('Note');
		} else {
			$desc     = prompts("Description", $desc);
			$note     = prompts("Outcome", option('Note'));
		}

		my $ref = Hier::Tasks->new(undef);

		$ref->set_type($type); 

		$ref->set_priority($pri);
		$ref->set_category($category);
		$ref->set_title($title);
		$ref->set_description($desc);
		$ref->set_note($note);

		$ref->insert();

		print "Created: ", $ref->get_tid(), "\n";
	}
}

sub first {
	my($text) = @_;
	$First = "$text\n" .
	 "  enter ^D to stop, entry not added\n" . 
	 "  use '.' to stop adding notes.\n";
}
sub prompts {
	my($prompt, $default) = @_;

	return $default if $default;
	my($text) = '';

	my($line) = prompt($prompt);
	for ($text=''; $line; $line=prompt("+ ")) {
		last if $line eq '.';
		$text .= $line . "\n";
	}
	chomp $text;
	return $text;
}

sub prompt {
	my($prompt, $default) = @_;

	return $default if defined $default && $default ne '';

	if ($prompt =~ /^[A-Z]/) {
		$prompt = sprintf("Add %-10s", $prompt . ':');
	}

	local($|) = 1;
	if ($First) {
		print $First;
		$First = '';
	}


	print $prompt;
	if (defined($_ = <STDIN>)) {
		chomp;

		return $_;
	}
	print "^D -- Bye --\n";
	exit 0;
}

1;  # don't forget to return a true value from the file
