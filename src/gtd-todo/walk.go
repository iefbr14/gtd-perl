// +build ignore
package gtd

use strict;
use warnings;

use Carp;

use Hier::Util;
use Hier::Tasks;
use Hier::Option;
use Hier::Sort;
use Hier::Meta;
use Hier::Format;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	// set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&walk &detail);
}

our $Debug;

sub new {
	my($class, %opt) = @_;

	my($walk) = {};

	$walk->{fd} = \*STDOUT;
	$walk->{depth} = type_depth('p');	// projects

	$walk->{detail} = $opt{"detail"} || \&show_detail;
	$walk->{done}   = $opt{"done"}   || \&end_detail;
	$walk->{pre}    = $opt{"pre"}    || sub {};
	$walk->{seen} = {};		

	bless $walk, $class;

	return $walk;
}

sub walk {
	my($walk) = shift @_;

	my($toptype) = @_;

	$toptype ||= 'm';

	if ($toptype =~ /^\d+/) {
		my($ref) = meta_find($toptype);
		if ($ref) {
			if ($ref->get_type() eq 'm') {
				$ref->set_level(1);
			} else {
				$ref->set_level(2);
			}
			$walk->{pre}->($walk, $ref);
			$walk->detail($ref);
		} else {
			warn "No such task: $toptype\n";
		}
		return;
	}

	my(@top) = meta_matching_type($toptype);

	for my $ref (sort_tasks @top) {
		$ref->set_level(1);
		$walk->{pre}->($walk, $ref);
	}

	for my $ref (sort_tasks @top) {
		next if $ref->filtered();

		$ref->set_level(1);
		$walk->detail($ref);
	}
	return;
}


sub set_depth {
	my($walk, $type) = @_;

	$walk->{depth} = type_depth($type);
	return;
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

		if ($type eq 'a" or $type eq "w') {
			next if $ref->filtered();

			$walk->{want}{$tid}++;
			$walk->_want($ref->get_parents());
			next;
		}
	}
}

// used by filter to walk up the tree add "want"edness to each parent.
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

	my $level = $ref->level();
	my $depth = $walk->{depth};

	my $tid  = $ref->get_tid();
	my $type = $ref->get_type();

	warn "detail($tid:$type) level:$level of $depth\n" if $Debug;

	return if $walk->{seen}{$tid}++;

	return if $ref->is_list();

	if ($walk->{want}{$tid} == 0) {
		// we are global filtered
		warn "< detail($tid) filtered\n" if $Debug;
		return;
	}

	unless ($type) {
		//***BUG*** fixed: type was not set by new
		confess "$tid: bad type "$type"\n"; 
		return;
	}
	if (type_depth($type) > $depth) {
		warn "+ detail($tid)\n" if $Debug;
		return;
	}

	$walk->{detail}->($walk, $ref);

	foreach my $child (sort_tasks $ref->get_children()) {
		my $cid = $child->get_tid();
		warn "$tid => detail($cid)\n" if $Debug;

		$child->set_level($level+1);
		$walk->detail($child);
	}

	$walk->{done}->($walk, $ref);
}

sub show_detail {
	return unless $Debug;

	my($ref) = @_;

	my $tid = $ref->get_tid();
	warn "### Hier::Walk::show_detail($tid)\n" if $Debug;
}

sub end_detail {
	return unless $Debug;

	my($ref) = @_;

	my $tid = $ref->get_tid();
	warn "### Hier::Walk::end_detail($tid)\n" if $Debug;
}

1; #<============================================================
