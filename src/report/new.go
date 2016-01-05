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

use Hier::Hier;
use Hier::Meta;
use Hier::Tasks;
use Hier::Util;
use Hier::Option;
use Hier::Prompt;

use Hier::Report::renumber;	# qw(next_avail_task);

my $First = '';
my $Parent;
my $P_ref;

###BUG### ^c in new kills report rc

# Usage:
#    new                               # type: inbox
#    new task                          # type: task
#    new proj                          # type: proj
#    new        I have to do this      # type: inbox (done)
#    new task   I have to do this      # type: task (done)
# and we mix in with a parent: 
#    new				# type: map parent
#    new task				# type: is task
#    new proj                           # type: is sub-project
#    new        I have to do this       # type: map parent (done)
#    new task   I have to do this       # type: is task (done)
#    new proj   I have to do this       # type: is proj (done)
#
# there are two paths here.  The first is the command line
# where everything is on the command line and is a one shot
# the other is the prompter version with defaults
#
sub Report_new {	#-- create a new action or project
	meta_filter('+all', '^tid', 'none');

	my($want) = '';
		
	if (@_) {
		my($type_arg) = type_val($_[0]);
		if ($type_arg) {
			$want = $type_arg;
			shift @_;
		}
	}

	my $parent = option('Current');
	if ($parent) {
		$P_ref = Hier::Tasks::find($parent);
		unless ($P_ref) {
			die "Can't use $parent no such task\n";
		}
		$Parent = $parent;
		unless ($want) {
			$want = $P_ref->get_type();
			$want =~ tr{mvogpawi}
				   {vogpaXXX};
		###BUG### in mapping sub-type prompmote actions to projects?
		die "Won't create sub-actions of actions" if $want eq 'X';
		}
	}

	$want ||= 'i';	# still unknown at this point!

	my($title) = meta_desc(@_);
	$title =~ s/^--\s*//;

	print "new: want=$want title=$title\n";

	# command line path
	if ($title) {
		new_item($want, $title);
		return;
	}

	if (is_type_hier($want)) {
		new_project($want);
	} else {
		new_action($want);
	}
}

sub is_type_hier {
	my($type) = @_;

	return 1 if $type =~ /^[mvogp]/;
	return 0;
}

# command line version, no prompting
sub new_item {
	my($type, $title) = @_;

	my($pri, $task, $category, $note, $desc, $line);

	$task     = option("Title") || $title;
	$pri      = option('Priority') || 4;
	$desc     = option("Desc") || '';

	$category = option('Category') || '';
	$note     = option('Note') || ''; 

	my($tid) = next_avail_task($type);
	my $ref = Hier::Tasks->new($tid);

	if ($pri > 5) {
		$pri -= 5;
		$ref->set_isSomeday('y');
	} else {
		$ref->set_isSomeday('n');
	}
	if ($type eq 'n') {
		$type = 'a';
		$ref->set_nextaction('y');
	} else {
		$ref->set_nextaction('n');
	}
	$ref->set_type($type);

	$ref->set_priority($pri);

	$ref->set_category($category);
	$ref->set_title($task);
	$ref->set_description($desc);
	$ref->set_note($note);


	$ref->set_parent_ids($Parent) if $Parent;
	$ref->insert();

	print "Created: ", $ref->get_tid(), "\n";
}

# detailed task
sub new_action {
	my($type) = @_;

	my($title, $pri, $category, $desc, $note, $line);

	my($type_name) = type_name($type);

	first("Enter $type_name: Task, Desc, Category, Notes...");

	$title    = input("Title", option('Title'));
	$pri      = input("Priority", option('Priority')) || 4;
	$desc     = prompt_desc("Desc", $desc);

	$category = input("Category", option('Category'));
	$note     = prompt_desc("Note", option('Note')); 

	my($tid) = next_avail_task('a');
	my $ref = Hier::Tasks->new($tid);

	if ($type eq 'n') {
		$type = 'a';
		$ref->set_nextaction('y');
	} else {
		$ref->set_nextaction('n');
	}
	$ref->set_type($type); # action/inbox/wait

	if ($pri > 5) {
		$pri -= 5;
		$ref->set_isSomeday('y');
	} else {
		$ref->set_isSomeday('n');
	}
	$ref->set_priority($pri);
	$ref->set_category($category);
	$ref->set_title($title);
	$ref->set_description($desc);
	$ref->set_note($note);

	$ref->set_parent_ids($Parent) if $Parent;
	$ref->insert();

	print "Created: ", $ref->get_tid(), "\n";
}


sub new_project {
	my($type) = @_;

	my($pri, $category, $title, $desc, $note);

	my($type_name) = type_name($type);

	first("Enter $type_name: Category, Title, Description, Outcome...");

	$category = input("Category", option('Category'));
	$title    = input("Title", option('Title'));
	$pri      = option('Priority') || 4;

	$desc     = prompt_desc("Description", option('Desc'));
	$note     = prompt_desc("Outcome", option('Note'));

	my($tid) = next_avail_task($type);
	my $ref = Hier::Tasks->new($tid);

	$ref->set_type($type); 
	$ref->set_nextaction('n');
	$ref->set_isSomeday('n');

	$ref->set_priority($pri);
	$ref->set_category($category);
	$ref->set_title($title);
	$ref->set_description($desc);
	$ref->set_note($note);

	$ref->set_parent_ids($Parent) if $Parent;
	$ref->insert();

	print "Created: ", $ref->get_tid(), "\n";
}

sub first {
	my($text) = @_;
	$First = "$text\n" .
	 "  enter ^D to stop, entry not added\n" . 
	 "  use '.' to stop adding notes.\n";
}

sub prompt_desc {
	my($prompt, $default) = @_;

	return $default if $default;
	my($text) = '';

	my($line) = prompt($prompt);
	for ($text=''; $line; $line=prompt("+")) {
		last if !defined $line;
		last if $line eq '.';

		$text .= $line . "\n";
	}
	chomp $text;
	return $text;
}

sub input {
	my($prompt, $default) = @_;

	return $default if defined $default && $default ne '';

	if ($prompt =~ /^[A-Z]/) {
		$prompt = sprintf("Add %-9s", $prompt . ':');
	}

	local($|) = 1;
	if ($First) {
		print $First;
		$First = '';
	}


	return prompt($prompt, '#');
}

1;  # don't forget to return a true value from the file
