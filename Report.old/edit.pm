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

use Hier::globals;
use Hier::util;
use Hier::db;
use Hier::Report::dump;
use Hier::Tasks;

sub Report_edit {
	my($cnt) = 0;
	my($key, $val, $changed);

	umask(0077);
    {
	open(my $fd, '>', "/tmp/todo.$$") or die;
	for my $tid (@_) {
		my $ref = $Task{$tid};

		unless (defined $ref) {
			print "No item $tid\n";
			print {$fd} "#*** no item $tid\n";
			next;
		}
		++$cnt;

		dump_ordered_ref($fd, $ref);
	}
	close($fd);
   }
	if ($cnt == 0) {
		unlink("/tmp/todo.$$");
		return;
	}
	system('vi', "/tmp/todo.$$");
   {
	open(my $fd, '<', "/tmp/todo.$$") or die;
	while (<$fd>) {
		next if /^#/;

		if (/^=-=$/) {
			save($changed);
			$changed = {};
			next;
		}
		chomp;

		next if /^$/;

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
	close($fd);
   }
	unlink("/tmp/todo.$$");

	exit 0;
}

sub save {
	my($changed) = @_;
	my($tid) = $changed->{todo_id};
	my($ref) = $Task{$tid};

	print "Saving $tid - $changed->{task} ...\n";

	my($val, $newval);
	my(@keys, @vals);
	my($u) = 0;

	for my $key (sort keys %$changed) {
		$val = $ref->{$key};
		$val = disp_parents($ref) if $key eq 'Parents';
		$newval = $changed->{$key};

		if (defined $val && defined $newval) {
			next if $val eq $newval;
			++$u;
			set($ref, $key, $newval);

			print "$key: $val -> $newval\n";
			next;
		}
		if (defined $newval) {	# val must be undefined
			++$u;
			set($ref, $key, $newval);

			print "$key: set to $newval\n";
			next;
		}
		if (defined $val) {	# newval must be undefined
			++$u;
			set($ref, $key, $newval);

			print "$key: deleted val $val\n";
			next;
		}
		# both undefined, don't care
	}

	if ($u == 0) {
		print "Item $tid unchanged\n";
		return;
	}

	gtd_update($ref);

	print  "Saved\n";
}

1;  # don't forget to return a true value from the file
