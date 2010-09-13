package Hier::Report::fixcct;

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

use Hier::Tasks;

sub Report_fixcct {	#-- Fix Categories/Contexts/Time Frames
	my($new_id, $id);

	report_header("Categories");
	for my $key (sort keys %Categories) {
		next if $key =~ /^\d+$/;
		$id = $Categories{$key} || '';

		next unless $key =~ s/^(\d+)://;
		$new_id =  $1;
	
		sql_fix_cct('category', $id, $new_id, $key);
	}
	report_header("Contexts");
	for my $key (sort keys %Contexts) {
		next if $key =~ /^\d+$/;
		$id = $Contexts{$key} || '';

		next unless $key =~ s/^(\d+)://;
		$new_id =  $1;
	
		sql_fix_cct('context', $id, $new_id, $key);
	}
	print "\n";
	report_header("Time Frames");
	for my $key (sort keys %Timeframes) {
		next if $key =~ /^\d+$/;
		$id = $Timeframes{$key} || '';

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
