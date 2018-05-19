package GTD::Report::checklist;

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

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &Report_checklist );
}

use GTD::Util;
use GTD::Meta;
use GTD::Format;

our $Debug = 0;

sub Report_checklist {	#-- display a check list
	meta_filter('+any', '^title', 'item');
#	meta_argv();
	my ($p) = shift @_;

	my ($id);
	if ($p) {
		if ($p =~ /^\d+$/) {
			list_records($id, "List: $p", meta_desc($p, @_));
			return;
		}
		if ($id = find_list($p)) {
			list_records($id, "List: $p", meta_desc($p, @_));
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
		my $title = $ref->get_title();
		my $pid  = 0;

		if ($ref->get_parent()) {
			$pid = $ref->get_parent()->get_tid();
		}

		print "pid: $pid tid: $tid => $title\n" if $Debug;

		if ($owner) {
			next if $pid != $owner;
			printf ("%5d [_] %s\n", $tid, $title);
		} else {
			printf ("%5d %s\n", $tid, $title);
		}
	}
}

1;  # don't forget to return a true value from the file
