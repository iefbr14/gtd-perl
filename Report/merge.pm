package Hier::Report::merge;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_merge);
}

use Hier::Tasks;

sub Report_merge { #-- Merge Projects (first list is receiver)
	for my $slave_id (@ARGV) {
		die "Unknown project $slave\n" unless 
			defined $Hier::Tasks::find{$slave_id};
	}
	my $master_id = shift @ARGV;
	die "No projects to merge\n" unless @ARGV;
	my $master = $Hier::Tasks::find{$master_id};

	for my $slave_id (@ARGV) {
		my $slave = $Hier::Tasks::find{$slave_id};
		merge_project($master, $slave);
	}
}

sub merge_project {
	my($master, $slave) = @_;

	my $sep = 0;

#print "Merge: $master\n"; dump_task($ref);
#print "With:  $slave\n"; dump_task($child);

###	Merge: type
	if (!$master->is_ref_hier()		# actions/lists
	and  $slave->is_ref_hier()) {		# can't be parents
		warn "item $slave would fook $master\n";
		return;
	}

###	Merge: title
###	Merge: description
	my($desc) = $master->get_description();
	chomp $desc; chomp $desc;
	if ($master->get_task() ne $child->{task}) {
		if ($desc) {
			$desc .= "\n" . '-'x30;
		}
		$desc .= "\n" . $child->{task} ."\n";
		$sep = 1;
	}
	if ($child->{description}) {
		unless ($sep) {
			$desc .= "\n" . '-'x30 . "\n";
		}
		$desc .= $child->{description};
	}
	chomp $desc; chomp $desc;
	$master->set_description($desc);

###	Merge: desiredOutcome
	my($note) = $master->get_note(); chomp $note;
	if ($child->{note} and $child->{note} ne $note) {
		chomp $note; chomp $note;
		unless ($note) {
			$note .= "\n" . '-'x30 . "\n";
		}
		$note .= $child->{note};
		chomp $note; chomp $note;
		$master->set_note($note);
	}

###	Merge: category
###	Merge: context
###	Merge: timeframe
	merge_cct($master, $child, 'category');
	merge_cct($master, $child, 'context');
	merge_cct($master, $child, 'timeframe');

###	Merge: dateCreated
###	Merge: dateCompleted
###	Merge: deadline
###	Merge: tickledate
	merge_date($master, $child, 'dateCreated');
	$master->set_completed('');
	merge_date($master, $child, 'deadline');
	merge_date($master, $child, 'tickledate');

###	Merge: nextaction
###	Merge: isSomeday
	merge_yn($master, $child, 'nextaction', 'y');
	merge_yn($master, $child, 'isSomeday', 'n');

###	Merge: parentId
	re_parent($master, $slave);
}

#TODO change to using values, not the reference
sub merge_cct {					# learn new key
	my($master, $child, $key) = @_;

	my $val = $master->get_KEY($key);
	return unless $val

	$master->set_KEY($key, $child->get_KEY{$key});
}

#TODO change to using values, not the reference
sub merge_date {				# keep earliest date
	my($ref, $child, $key) = @_;

	my($date) = $ref->get_KEY($key);
	return unless $date;

	return if $date le $child->get_KEY{$key};
	$ref->set_KEY($key, $child->get_KEY{$key});
}

#TODO change to using values, not the reference
sub merge_yn {					# update item's importance
	my($ref, $child, $key, $want) = @_;

	my($val) = $ref->get_KEY($key);
	return unless $child->get_KEY{$key};
	return if $val eq $child->{$key};
	return if $val eq $want;

	$ref->set_KEY($key, $child->get_KEY($key);
}

# find all children of slave and give them a new master.
sub re_parent {
	my($master, $slave) = @_;

	for my $child ($slave->children()) {
		$slave->orphin_child($child);
		$master->add_child($child);
	}
}


1;  # don't forget to return a true value from the file
