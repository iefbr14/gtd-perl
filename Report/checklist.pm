package Hier::Report::checklist;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &Report_checklist );
}

use Hier::util;
use Hier::Meta;

my $Debug = 0;

sub Report_checklist {	#-- display a check list
#	meta_argv();
	my ($p) = shift @ARGV;
	
	my ($id);
	if ($p) {
		if ($p =~ /^\d+$/) {
			list_records($id, "List: $p", meta_desc(@ARGV));
			return;
		} 
		if ($id = find_list($p)) {
			list_records($id, "List: $p", meta_desc(@ARGV));
		} else {
			print "Can't find a list by name of $p\n";
		}
	} else {
		list_lists();
	}
}

sub find_list {
	my($list_name) = @_;

	my($pid, $tid, $proj, $type, $f);
	my($Dates) = '';

	# find all records.
	for my $ref (meta_all()) {
		$tid = $ref->get_tid();
		$type = $ref->get_type();

		next unless $type =~ /[LC]/;

		return $tid if $ref->get_title() =~ /\Q$list_name\E/i;
	}
	return;
}

sub list_lists {
	report_header('Lists');
	disp_list('L', 0);
	report_header('Checklists');
	disp_list('C', 0);
}


sub list_records {
	my($list_id, $typename, $desc) = @_;

	report_header($typename, $desc);

	my($pid, $tid, $proj, $type, $f);

	# find all records.
	disp_list('T', $list_id);
}

sub disp_list {
	my ($record_type, $owner) = @_;

	for my $ref (meta_matching_type($record_type)) {
		my $tid = $ref->get_tid();
		my $pid = $ref->get_parent()->get_tid();
		my $title = $ref->get_title();

		print "pid: $pid tid: $tid => $title\n" if $Debug;

		if ($owner) {
			next if $pid != $owner;	
			printf ("%5d [_] %s\n", $tid, $title);
		} else {
			printf ("%5d %s\n", $tid, $title);
		}
	}
}

### format:
### 99	P:Title	[_] A:Title
sub disp {
	my($ref) = @_;

	my($tid) = $ref->get_tid();

	my($key) = action_disp($ref);

	my $pri = $ref->get_priority() || 3;
	my $type = uc($ref->get_type());

	return "$type:$tid $key <$pri> $ref->get_task()";
}

sub by_task {
	return $a->get_title() cmp $b->get_title()
	    or $a->get_tid() <=> $b->get_tid();
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

1;  # don't forget to return a true value from the file
