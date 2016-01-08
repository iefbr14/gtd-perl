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


//-- Command line update of an action/project
func Report_update(args []string) {
	my($task, $desc) = @_;

	unless (defined $task) {
		print "NO task specified to update\n";
		return;
	}
	my $ref = gtd.Meta_find($task);
	unless (defined $ref) {
		print "Task $task not found to update\n";
		return;
	}

	my $val;

	if ($val = option("Category")) {
		$ref->set_category($val);
	}

	if ($val = option("Context")) {
		$ref->set_context($val);
	}

	if ($val = option("Timeframe")) {
		$ref->set_timeframe($val);
	}

	if ($val = option("Note")) {
		$ref->set_note($val);
	}

	if ($val = option("Priority")) {
		$ref->set_priority($val);
	}

	if ($val = option("Complete")) {
		$ref->set_priority($val);
	}

	if ($val = option("Description")) {
		$ref->set_description($val);
	}

	$ref->update();
}
