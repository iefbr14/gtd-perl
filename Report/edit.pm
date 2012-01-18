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
	my($cnt) = 0;
	my($key, $val, $changed);

	umask(0077);

	display_mode('odump');	# *** need ordered dump ***

    {
	open(my $fd, '>', "/tmp/todo.$$") or die;
	for my $tid (@_) {
		my $ref = meta_find($tid);

		unless (defined $ref) {
			print "No item $tid\n";
			print {$fd} "#*** no item $tid\n";
			next;
		}
		++$cnt;

		display_fd_task($fd, $ref);
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
	close($fd);
   }
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

		###BUG### handle missing keys from @Ordered (see Report/dump.pm)
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
