package Hier::Report::edit;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_edit);
}

use Hier::util;
use Hier::Meta;

use Hier::Format;

sub Report_edit {	#-- Edit listed actions/projects
	my($key, $val, $changed);

	meta_filter('+all', '^tid', 'none');

	my(@list) = meta_pick(@_);
	if (@list == 0) {
		print "No items to edit\n";
		exit;
	}
    
	umask(0077);
	open(my $ofd, '>', "/tmp/todo.$$") or die;
	for my $ref (@list) {
		disp_ordered_dump($ofd, $ref);
	}
	close($ofd);
   
	system('vi', "/tmp/todo.$$");
 
	open(my $ifd, '<', "/tmp/todo.$$") or die;
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
			die "Can't parse: $_\n";
		}

	}
	save($changed) if %$changed;
	close($ifd);

	unlink("/tmp/todo.$$");

	exit 0;
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

		# Specal values from disp_ordered_dump
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
		if (defined $newval) {	# val must be undefined
			++$u;
			$ref->set_KEY($key, $newval);

			$Changed .= "$key: set to $newval\n";
			next;
		}
		if (defined $val) {	# newval must be undefined
			++$u;
			$ref->set_KEY($key, $newval);

			$Changed .= "$key: removed val $val\n";
			next;
		}
		# both undefined, don't care
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
