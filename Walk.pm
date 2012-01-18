package Hier::Walk;

use strict;
use warnings;

use Hier::util;
use Hier::Tasks;
use Hier::Option;
use Hier::Sort;
use Hier::Meta;
use Hier::Format;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&walk &detail);
}

my $Debug;

sub new {
	my($class) = @_;

	my($walk) = {};

	$walk->{fd} = \*STDOUT;
	$walk->{level} = 0;
	$walk->{depth} = type_depth('p');	# projects

	bless $walk, $class;

	$Debug = option('Debug');

	return $walk;
}

sub walk {
	my($self, $toptype) = @_;

	$toptype ||= 'm';

	if ($toptype =~ /^\d+/) {
		my($ref) = meta_find($toptype);
		if ($ref) {
			$self->detail($ref);
		} else {
			warn "No such task: $toptype\n";
		}
		return;
	}

	my(@top) = meta_matching_type($toptype);

	for my $ref (sort_tasks @top) {
		$self->detail($ref);
	}
	return;
}


sub set_depth {
	my($walk, $type) = @_;

	$walk->{depth} = type_depth($type);
	return;
}


sub by_name {
	return $a->get_title() cmp $b->get_title()
	||     $a->get_tid()   <=> $b->get_tid();
}

sub filter {
	my($walk) = shift @_;

	my($tid, $type);
	foreach my $ref (Hier::Tasks::all()) {
		$tid = $ref->get_tid;
		$walk->{want}{$tid} = 1;
		$walk->{want}{$tid} = 0 if $ref->filtered();
	}
	return;

	foreach my $ref (Hier::Tasks::all()) {
		$tid = $ref->get_tid();
		$type = $ref->get_type();

		if ($type eq 'p') {
			next if $ref->filtered();

			$walk->{want}{$tid}++;
			$walk->_want($ref->get_parents());
			next;
		}

		if ($type eq 'a' or $type eq 'w') {
			next if $ref->filtered();

			$walk->{want}{$tid}++;
			$walk->_want($ref->get_parents());
			next;
		}
	}
}

# used by filter to walk up the tree add "want"edness to each parent.
sub _want {
	my($walk) = shift @_;

	my($pid);
	foreach my $ref (@_) {
		$pid = $ref->get_tid();
		next if $walk->{want}{$pid}++;

		$walk->_want($ref->get_parents());
	}
}

sub detail {
	my($walk, $ref) = @_;
	my($sid, $name, $cnt, $desc, $pri, $done);

	my $level = $walk->{level};
	my $depth = $walk->{depth};

	my $tid  = $ref->get_tid();
	my $type = $ref->get_type();

	return if $walk->{seen}{$tid}++;

	return if $ref->is_list();
	return if $ref->filtered();

	if ($walk->{want}{$tid} == 0) {
		# we are global filtered
		warn "< detail($tid} filtered\n" if $Debug;
		return;
	}

	if (type_depth($type) > $depth) {
		warn "+ detail($tid}\n" if $Debug;
		return;
	}

	if ($ref->is_task()) {
		if ($ref->filtered()) {
			# we are item filtered
			warn "< detail($tid} filtered\n" if $Debug;
			return;
		} 
		$walk->task_detail($ref);
		return;
	}

	$walk->hier_detail($ref);
	$walk->{level}++;

	foreach my $child (sort_tasks $ref->get_children()) {
		warn "$tid => detail($child)\n" if $Debug;

		$walk->detail($child);
	}

	$walk->{level}--;
	
	$walk->end_detail($ref);
}

1;  # don't forget to return a true value from the file
