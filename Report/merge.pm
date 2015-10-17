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

use Hier::Meta;

sub Report_merge { #-- Merge Projects (first list is receiver)
	for my $slave_id (@_) {
		die "Unknown project $slave_id\n" unless 
			defined meta_find($slave_id);
	}
	my $master_id = shift @_;
	die "No projects to merge\n" unless @_;
	my $master = meta_find($master_id);

	for my $slave_id (@_) {
		my $slave = meta_find($slave_id);
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
	if (!$master->is_hier()		# actions/lists
	and  $slave->is_hier()) {		# can't be parents
		warn "item $slave would fook $master\n";
		return;
	}

###	Merge: title
###	Merge: description
	my($desc) = $master->get_description();
	chomp $desc; chomp $desc;
	if ($master->get_title() ne $slave->get_title()) {
		if ($desc) {
			$desc .= "\n" . '-'x30;
		}
		$desc .= "\n" . $slave->get_title() ."\n";
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

###	Merge: created (dateCreated)
###	Merge: due (deadline)
###	Merge: tickledate (tickleDate)
	merge_date($master, $slave, 'created');
	merge_date($master, $slave, 'due');
	merge_date($master, $slave, 'tickledate');

###	Merge: completed (dateCompleted)
	merge_completed($master, $slave);

###	Merge: nextaction
###	Merge: isSomeday
	merge_yn($master, $slave, 'nextaction', 'y');
	merge_yn($master, $slave, 'isSomeday', 'n');


###	Merge: recur
###	Merge: recurdesc

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

	my($sdate) = $slave->get_KEY($key);	# grab slave date
print "S $key = $sdate\n";
	return unless $sdate;			# no date in slave
	return if $sdate =~ m/^0000/;		# bogus date prefix

	my($mdate)  = $ref->get_KEY($key);	# grab master date
print "M $key = $mdate\n";
	$mdate = '' if $mdate =~ m/^0000/;	# bogus date prefix

	unless ($mdate) {			# no master, use slave
		$ref->set_KEY($key, $sdate);
		print "Date for $key set to $sdate (was missing)\n";
		return;
	}

	# both master and slave exists, keep earlier (lesser)
	return if $mdate le $sdate; # master lesser, just keep it

	$ref->set_KEY($key, $sdate); # slave lesser, set it
	print "Date for $key set to $sdate (was $mdate)\n";
}

#TODO change to using values, not the reference
sub merge_completed {				# keep earliest date
	my($ref, $slave) = @_;

	my($mdate) = $ref->get_completed();	# grab master date
	$mdate = '' if $mdate =~ m/^0000/;	# bogus date prefix

	return unless $mdate;			# no master completed date

print "M done = $mdate\n";

	my($sdate) = $slave->get_completed();	# grab slave date
	$sdate = '' if $sdate =~ m/^0000/;	# bogus date prefix

print "S done = $sdate\n";

	unless ($sdate) {			# no master, use slave
		$ref->set_completed('');
		print "Done Date removed (was $mdate)\n";
		return;
	}

	# both master and slave exists, later (greater)
	return if $mdate ge $sdate; # master greater, just keep it

	$ref->set_completed($sdate); # slave greater, set it
	print "Done Date set to $sdate (was $mdate)\n";
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
		my($cid) = $child->get_tid();
		print "move S child $cid\n";
		$slave->orphin_child($child);
		$master->add_child($child);
	}
}


1;  # don't forget to return a true value from the file
