package Hier::Report::update;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_udpate);
}

use Hier::globals;
use Hier::Tasks;

sub Report_update_task {
	my($task, $desc) = @_;

	my($ref) = $Task{$task};
	unless (defined $ref) {
		print "Task $task not found to update\n";
		return;
	}

	set($ref, category    => $Category)  if $Category;
	set($ref, context     => $Context)   if $Context;
	set($ref, context     => $Timeframe) if $Timeframe;
	set($ref, note        => $Note)      if $Note;
	set($ref, priority    => $Priority)  if $Priority;
	set($ref, description => $desc)      if $desc;

	gtd_update($ref);
}

1;  # don't forget to return a true value from the file
