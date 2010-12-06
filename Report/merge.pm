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
		die "Unknown project $slave_id\n" unless 
			defined Hier::Tasks::find($slave_id);
	}
	my $master_id = shift @ARGV;
	die "No projects to merge\n" unless @ARGV;
	my $master = Hier::Tasks::find($master_id);

	for my $slave_id (@ARGV) {
		my $slave = Hier::Tasks::find($slave_id);
		merge_project($master, $slave);
		$master->update();
		$slave->delete();
	}
}

sub merge_project {
	my($master, $slave) = @_;

	my $sep = 0;

#print "Merge: $master\n"; dump_task($ref);
#print "With:  $slave\n"; dump_task($slave);

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
	if ($master->get_task() ne $slave->get_task()) {
		if ($desc) {
			$desc .= "\n" . '-'x30;
		}
		$desc .= "\n" . $slave->get_task() ."\n";
		$sep = 1;
	}
	if ($slave->get_description()) {
		unless ($sep) {
			$desc .= "\n" . '-'x30 . "\n";
		}
		$desc .= $slave->get_description();
	}
	chomp $desc; chomp $desc;
	$master->set_description($desc);

###	Merge: desiredOutcome
	my($note) = $master->get_note(); chomp $note;
	my($snote) = $slave->get_note();
	if ($snote && ($snote ne $note)) {
		chomp $note; chomp $note;
		if ($note) {
			$note .= "\n" . '-'x30 . "\n";
		}
		$note .= $snote;
		chomp $note; chomp $note;
		$master->set_note($note);
	}

###	Merge: category
###	Merge: context
###	Merge: timeframe
	merge_cct($master, $slave, 'category');
	merge_cct($master, $slave, 'context');
	merge_cct($master, $slave, 'timeframe');

###	Merge: dateCreated
###	Merge: dateCompleted
###	Merge: deadline
###	Merge: tickledate
	merge_date($master, $slave, 'dateCreated');
	$master->set_completed('');
	merge_date($master, $slave, 'deadline');
	merge_date($master, $slave, 'tickledate');

###	Merge: nextaction
###	Merge: isSomeday
	merge_yn($master, $slave, 'nextaction', 'y');
	merge_yn($master, $slave, 'isSomeday', 'n');


###	Merge: priority
	merge_date($master, $slave, 'doit');
	merge_first($master, $slave, 'owner');
	merge_first($master, $slave, 'private');
	merge_first($master, $slave, 'palm_id');

	$master->set_effort(
		($master->get_effort() || 0) +
		($slave->get_effort() || 0)
	);
		
	merge_first($master, $slave, 'resource');
	merge_tag($master, $slave, 'depends');
	merge_tag($master, $slave, 'tags');

###	Merge: parentId
	re_parent($master, $slave);

}

#TODO change to using values, not the reference
sub merge_cct {					# learn new key
	my($master, $slave, $key) = @_;

	my $val = $master->get_KEY($key);
	return if $val;

	$master->set_KEY($key, $slave->get_KEY($key));
}

#TODO change to using values, not the reference
sub merge_date {				# keep earliest date
	my($ref, $slave, $key) = @_;

	my($date) = $ref->get_KEY($key);
	return unless $date;

	return if $date le $slave->get_KEY($key);
	$ref->set_KEY($key, $slave->get_KEY($key));
}

#TODO change to using values, not the reference
sub merge_yn {					# update item's importance
	my($ref, $slave, $key, $want) = @_;

	my($val) = $ref->get_KEY($key);
	return unless $slave->get_KEY($key);
	return if $val eq $slave->get_KEY($key);
	return if $val eq $want;

	$ref->set_KEY($key, $slave->get_KEY($key));
}

#TODO change to using values, not the reference
sub merge_first {				# update item's importance
	my($ref, $slave, $key) = @_;

	my($val) = $ref->get_KEY($key);

	return if $val;		# master has a value keep it

	$val = $slave->get_KEY($key);

	return unless $val;	# slave doesn't have a value ... done

	$ref->set_KEY($key, $val);	# slave has a value, set it
}

#TODO change to using values, not the reference
sub merge_tag {				# update item's importance
	my($ref, $slave, $key) = @_;

	my($sval) = $slave->get_KEY($key);

	return unless $sval;	# slave doesn't have a value ... done

	my($mval) = $ref->get_KEY($key);

	if ($mval) {
		$ref->set_KEY($key, "$mval,$sval");	# both have vals
	} else {
		$ref->set_KEY($key, $sval);	# slave only has a value
	}
}

# find all children of slave and give them a new master.
sub re_parent {
	my($master, $slave) = @_;

	for my $child ($slave->get_children()) {
		$slave->orphin_child($child);
		$master->add_child($child);
	}
}


1;  # don't forget to return a true value from the file
