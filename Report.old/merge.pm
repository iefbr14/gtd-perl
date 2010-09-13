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

use Hier::globals;
use Hier::Tasks;

sub Report_merge { #-- Merge Projects (first list is receiver)
	for my $slave (@ARGV) {
		die "Unknown project $slave\n" unless defined $Task{$slave};
	}
	my $master = shift @ARGV;
	die "No projects to merge\n" unless @ARGV;

	for my $slave (@ARGV) {
		merge_project($master, $slave);
	}
}

sub merge_project {
	my($master, $slave) = @_;

	my $sep = 0;
	my $ref = $Task{$master};
	my $child = $Task{$slave};

#print "Merge: $master\n"; dump_task($ref);
#print "With:  $slave\n"; dump_task($child);

###	Merge: type
	if (!is_ref_hier($ref)		# actions
	and  is_ref_hier($child)) {	# can't be parents
		warn "item $slave would fook $master\n";
		return;
	}

###	Merge: title
###	Merge: description
	my($desc) = $ref->{description};
	chomp $desc; chomp $desc;
	if ($ref->{task} ne $child->{task}) {
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
	set($ref, 'description', $desc);

###	Merge: desiredOutcome
	my($note) = $ref->{note}; chomp $note;
	if ($child->{note} and $child->{note} ne $note) {
		chomp $note; chomp $note;
		unless ($note) {
			$note .= "\n" . '-'x30 . "\n";
		}
		$note .= $child->{note};
		chomp $note; chomp $note;
		set($ref, 'note', $note);
	}

###	Merge: category
###	Merge: context
###	Merge: timeframe
	merge_cct($ref, $child, 'category');
	merge_cct($ref, $child, 'context');
	merge_cct($ref, $child, 'timeframe');

###	Merge: dateCreated
###	Merge: dateCompleted
###	Merge: deadline
###	Merge: tickledate
	merge_date($ref, $child, 'dateCreated');
	set($ref, 'dateCompleted', undef, 1);
	merge_date($ref, $child, 'deadline');
	merge_date($ref, $child, 'tickledate');

###	Merge: nextaction
###	Merge: isSomeday
	merge_yn($ref, $child, 'nextaction', 'y');
	merge_yn($ref, $child, 'isSomeday', 'n');

###	Merge: parentId
	re_parent($master, $slave);
}

sub merge_cct {					# learn new key
	my($ref, $child, $key) = @_;

	return if $ref->{$key};
	return unless $child->{$key};

	set($ref, $key, $child->{$key});
}

sub merge_date {				# keep earliest date
	my($ref, $child, $key) = @_;

	return unless $child->{key};
	if ($ref->{key}) {
		return if $ref->{$key} le $child->{$key};
	}
	set($ref, $key, $child->{$key});
}

sub merge_yn {					# update item's importance
	my($ref, $child, $key, $want) = @_;

	return unless $child->{key};
	if ($ref->{key}) {
		return if $ref->{$key} eq $child->{$key};
		return if $ref->{$key} eq $want;
	}

	set($ref, $key, $child->{$key});
}

# find all children of slave and give them a new master.
sub re_parent {
	my($master, $slave) = @_;

	G_sql("update gtd_lookup set parentId=$master where parentId=$slave");
	my($ref);
	for my $tid (keys %Task) {
		$ref = $Task{$tid};

		next unless defined $ref->{_parents};
		next unless defined $ref->{_parents}{$master};

		$ref->{_parents}{$slave} = 1;
		delete $ref->{_parents}{$master};
	}
	G_sql("delete from gtd_lookup where itemId=$slave");
	G_sql("update gtd_tagmap set itemId=$master where itemId=$slave");
}


1;  # don't forget to return a true value from the file
