package Hier::Report::fixcct;

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
	@EXPORT      = qw(&Report_fixcct);
}

use Hier::Meta;

sub Report_fixcct {	#-- Fix Categories/Contexts/Time Frames
	my($new_id, $id);

	report_header("Categories");
	my($Category) = Hier::CCT->use('Category');
	for my $key (sort $Category->keys()) {
		$id = $Category->get($key);

		next unless $key =~ s/^(\d+)://;
		$new_id =  $1;
	
		sql_fix_cct('category', $id, $new_id, $key);
	}
	report_header("Contexts");
	my($Context) = Hier::CCT->use('Context');
	for my $key (sort $Context->keys()) {
		$id = $Context->get($key);

		next unless $key =~ s/^(\d+)://;
		$new_id =  $1;
	
		sql_fix_cct('context', $id, $new_id, $key);
	}
	print "\n";
	report_header("Time Frames");
	my($Timeframe) = Hier::CCT->use('Timeframe');
	for my $key (sort $Timeframe->keys()) {
		$id = $Timeframe->get($key) || '';

		next unless $key =~ s/^(\d+)://;
		$new_id =  $1;
	
		sql_fix_cct('timeframe', $id, $new_id, $key);
	}
	print "\n";
}

sub sql_fix_cct {
	my($hint, $old_id, $new_id, $val) = @_;

	my($table, $keycol, $valcol);
	if ($hint eq 'category') {
		$table = G_table('categories');
		$keycol = 'categoryId';
		$valcol = 'category';
	} elsif ($hint eq 'context') {
		$table = G_table('context');
		$keycol = 'contextId';
		$valcol = 'name';
	} elsif ($hint eq 'timeframe') {
		$table = G_table('timeitems');
		$keycol = 'timeframeId';
		$valcol = 'timeframe';
	} else {
		die;
	}
	my($itemstatus) = G_table('itemstatus');

	G_sql("update $table set $keycol=$new_id, $valcol=? where $keycol = $old_id", $val);
	G_sql("update $itemstatus set $keycol=$new_id where $keycol = $old_id");

}


1;  # don't forget to return a true value from the file
