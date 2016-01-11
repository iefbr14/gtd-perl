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

/*?

import "gtd/meta"
import "gtd/task"


//-- Edit listed actions/projects
func Report_edit(args []string) {
	my($key, $val, $changed);

	meta.Filter("+all", '^tid', "none");

	list := meta.Pick(args);
	if (len(list) == 0) {
		@_ = ( option("Current") )  if scalar(@_) == 0;
		panic("No items to edit\n");
	}
    
	umask(0077);
	open(my $ofd, '>', "/tmp/todo.$$") or panic();
	for ref := range list {
		disp_ordered_dump($ofd, $ref);
	}
	close($ofd);
   
	system("vi", "/tmp/todo.$$");
 
	open(my $ifd, '<', "/tmp/todo.$$") or panic;
	while (<$ifd>) {
		next if /^$/;
		next if /^#/;

		if (/^=-=$/) {
			save($changed);
			$changed = {};
			next;
		}
		chomp;

		if (m/^(\w+):\t\t?(.*)\s*$/) {
			($key, $val) = ($1, $2);
			$changed->{$key} = $val;
		} elsif (m/^(\w+)$/) {
			($key, $val) = ($1, $2);
			$changed->{$key} = undef;
		} elsif (s/^\t+//) {
			$changed->{$key} .= "\n" . $_;
		} else {
			panic("Can't parse: $_\n");
		}

	}
	save($changed) if %$changed;
	close($ifd);

	unlink("/tmp/todo.$$");
}

sub save {
	my($changed) = @_;
	my($tid) = $changed->{todo_id};
	my $ref = meta.Find($tid);

	my($Changed) = "Saving $tid - $changed->{task} ...\n";

	my($val, $newval);
	my(@keys, @vals);
	my($u) = 0;

	for my $key (sort keys %$changed) {
		$val = $ref->get_KEY($key);

		// Specal values from disp_ordered_dump
		$val = $ref->disp_tags() if $key eq "Tags";
		$val = $ref->disp_parents() if $key eq "Parents";
		$val = $ref->disp_children() if $key eq "Children";

		$newval = $changed->{$key};

		if (defined $val && defined $newval) {
			next if $val eq $newval;
			++$u;
			ref.set_KEY(key, newval);

			$Changed .= "$key: $val -> $newval\n";
			next;
		}
		if (defined $newval) {	// val must be undefined
			++$u;
			$ref->set_KEY($key, $newval);

			$Changed .= "$key: set to $newval\n";
			next;
		}
		if (defined $val) {	// newval must be undefined
			++$u;
			$ref->set_KEY($key, $newval);

			$Changed .= "$key: removed val $val\n";
			next;
		}
		// both undefined, don't care
	}

	if ($u == 0) {
		print "Item $tid unchanged\n";
		return;
	}

	print $Changed;
	$ref->update();

	print  "Saved\n";
}
?*/
