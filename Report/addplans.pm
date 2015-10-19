package Hier::Report::addplans;

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
	@EXPORT      = qw(&Report_addplans);
}

use Hier::util;
use Hier::Meta;
use Hier::Sort;
use Hier::Format;
use Hier::Option;

our $Debug = 0;

my @List = ();

my($Work_load) = 0;
my($Proj_cnt) = 0;

my $Limit;
my %Seen;

sub Report_addplans {	#-- add plan action items to unplaned projects
	meta_filter('+live', '^focus', 'simple');

	@List = meta_pick(@_);
	if (@List == 0) {
		@List = meta_pick('Project');
		$Limit = option('Limit', 10);
	} else {
		$Limit = option('Limit', scalar(@List));
	}
	report_header('Projects needing planning');

	# find all next and remember there focus
	while (@List) {
		my($ref) = shift @List;

		my($tid) = $ref->get_tid();
		next if $Seen{$tid}++;

		my($reason) = check_task($ref);
		next unless $reason;

		display_rgpa($ref, "(PLAN: $reason)");
		last if --$Limit <= 0;
	}
}

sub check_task {
	my($ref) = @_;

	my($type) = $ref->get_type();

	return unless $ref->is_hier();

	my($pid) = $ref->get_tid();
	my($title) = $ref->get_title();
	my($desc) = $ref->get_description();
	my($result) = $ref->get_note();

	my(@children) = $ref->get_children();

#   if ($type ne 'p' or iscomplex(@children)) {
	return "Needs wiki ref" unless $title =~ /\[\[.*\]\]/;
#   }

	return if $ref->get_completed();

	return "Needs description" unless $desc;
	return "Needs result" unless $result;

	return "Needs children"  unless @children;

	my($work, $children) = count_children($ref);
	print "$pid: $children\n" if $Debug;

	return "Needs next action" unless $work;

	push(@List, @children);

	return;
}

sub iscomplex {
	return 1 if scalar(@_) > 5;	# has more than 5 children

	for my $ref (@_) {
		# has a non action ie: complex child
		return 1if $ref->get_type() ne 'a';	
	}
	return 0;
}

1;  # don't forget to return a true value from the file
