package GTD::Report::print;

=head1 NAME

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

=cut

use strict;
use warnings;

use Switch;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &Report_print );
}

use GTD::Util;
use GTD::Tasks;
use GTD::Meta;
use GTD::Format;
use GTD::Option;

my $Layout = 'Text';

sub Report_print {	#-- display records in dump format based on format type
	# everybody into the pool by id
	meta_filter('+any', '^tid', 'doit');

	$Layout = ucfirst(lc(option('Layout', 'Text')));

	for my $ref (meta_pick(@_)) {
		print_ref($ref);
	}
}

sub print_ref {
	my($ref) = @_;

	my($tid)         = $ref->get_tid();
	my($type)        = $ref->get_type();
	my($typename)    = type_name($type);
	my($nextaction)  = $ref->is_nextaction() ? ' Next-action' : '';
	my($someday)      = $ref->is_someday() ? ' (someday)' :'';

	my($task)        = $ref->get_title();
	my($description) = $ref->get_description();
	my($note)        = $ref->get_note();

	my($category)    = $ref->get_category();
	my($context)     = $ref->get_context();
	my($timeframe)   = $ref->get_timeframe();
	my($created)     = $ref->get_created();
	my($doit)        = $ref->get_doit();
	my($modified)    = $ref->get_modified();
	my($tickledate)  = $ref->get_tickledate();
	my($due)         = $ref->get_due();
	my($completed)   = $ref->get_completed();

	my($priority)    = $ref->get_priority();
	my($effort)      = $ref->get_effort();
	my($resource)    = $ref->get_resource();
	my($depends)     = $ref->get_depends();

	my($tags)        = $ref->disp_tags();


	title($typename);   print "$tid:\t$task\n\n";
	title("Purpose");   print $description, "\n";
	title("Outcome");   print $note, "\n";

	title("Actions");

	my(@children) =$ref->get_children();

	if (@children == 0) {
		print "* [_] Plan and add tasks for $tid\n";
	}

	for my $cref (@children) {
		print "* [_] ";
		display_task($cref, '');
		br();
	}

	hr();

	pre(<<"EOF");
t,pri,s,n: $typename $tid -- pri:$priority$nextaction$someday
cct:       $category $context $timeframe
tags:      $tags

created:   $created
doit:      $doit
modified:  $modified
tickle:    $tickledate
due:       $due
completed: $completed

effort:    $effort
resource:  $resource
depends:   $depends

EOF

	hr();

}

sub pre {
	my($text) = @_;

	chomp $text;

	switch ($Layout) {
	case 'Text' { print "$text\n"; }
	case 'Wiki' { print "<pre>$text</pre>\n\n"; }
	case 'Html' { print "<pre> $text <preh1>\n"; }
	case 'Man'  { print ".EX\n$text\n.EE\n"; }
	}
}

sub br {
	switch ($Layout) {
	case 'Text' { }
	case 'Wiki' { print "<br>\n";}
	case 'Html' { print "<br>\n"; }
	case 'Man'  { print ".br\n"; }
	}
}
sub hr {
	switch ($Layout) {
	case 'Text' { print '-'x78, "\n"; }
	case 'Wiki' { print "------------------------------\n"; }
	case 'Html' { print "<hr>\n"; }
	case 'Man'  { print "\\l'6i\n"; }
	}
}

sub para {
	my($text) = @_;

	chomp $text;

	switch ($Layout) {
	case 'Text' { print $text,"\n"; }
	case 'Wiki' { print "== $text ==\n\n"; }
	case 'Html' { print "<h1> $text </h1>\n"; }
	case 'Man'  { print ".SH \"$text\"\n"; }
	}
}

sub title {
	my($text) = @_;

	chomp $text;

	switch ($Layout) {
	case 'Text' { print "== $text ==\n\n"; }
	case 'Wiki' { print "== $text ==\n\n"; }
	case 'Html' { print "<h1> $text </h1>\n"; }
	case 'Man'  { print ".SH \"$text\"\n"; }
	}
}

1;  # don't forget to return a true value from the file
