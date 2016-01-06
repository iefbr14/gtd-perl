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

	// set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_edit);
}

use Hier::Util;
use Hier::Meta;

use Hier::Option;
use Hier::Format;

sub Report_edit {	//-- Edit listed actions/projects
	my($key, $val, $changed);

	meta_filter('+all', '^tid', 'none');

	@_ = ( option('Current') )  if scalar(@_) == 0;

	my(@list) = meta_pick(@_);
	if (@list == 0) {
		panic("No items to edit\n");
	}
    
	umask(0077);
	open(my $ofd, '>', "/tmp/todo.$$") or panic();
	for my $ref (@list) {
		disp_ordered_dump($ofd, $ref);
	}
	close($ofd);
   
	system('vi', "/tmp/todo.$$");
 
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
	my $ref = meta_find($tid);

	my($Changed) = "Saving $tid - $changed->{task} ...\n";

	my($val, $newval);
	my(@keys, @vals);
	my($u) = 0;

	for my $key (sort keys %$changed) {
		$val = $ref->get_KEY($key);

		// Specal values from disp_ordered_dump
		$val = $ref->disp_tags() if $key eq 'Tags';
		$val = $ref->disp_parents() if $key eq 'Parents';
		$val = $ref->disp_children() if $key eq 'Children';

		$newval = $changed->{$key};

		if (defined $val && defined $newval) {
			next if $val eq $newval;
			++$u;
			$ref->set_KEY($key, $newval);

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

1;  # don't forget to return a true value from the file
