package Hier::Report::bulkload;

=head1 Bulk Load Syntax

  num:	Id of Roal/Goal/Proj/Action (Tab/Empty for New)
  type:	Type of Id (R/G/P) (if no num, will lookup this entry)
 or
  [_]	Next Action
  [ ]	Action
  [*]	Done
  [X]	Delete
  [-]	Hidden
  { }	Somday/maybe
 or
  ?attr	Attribute
  +	Description
  =	Result
  @cct	Category/Context/Timeframe
  *tag	Tag(s)
  #	comment
 or	
	Blank line end of group

=cut

use strict;
use warnings;

use Hier::Tasks;
use Hier::Option;

my $Parent;
my $Type;

sub Report_bulkload { #-- Create Projects/Actions items from a file
	my($pid);

	my($action) = \&add_nothing;
	my($desc) = '';

	my($parents) = {};

	my(@lines);

	for (;;) {
		if (@lines) {
			$_ = shift @lines;
		} else {
			$_ = <>;
			last unless defined $_;
			chomp;
		}

		next if /^#/;

		if (s/^(\d+)\t[A-Z]:\s*//) {
			&$action($parents, $desc);
			$action = \&add_update;
			$pid = $1;
			$parents->{me} = $pid;
			next;
		}
		if (s/^R:\s*//) {
			&$action($parents, $desc);

			$pid = find_hier('r', $_);
			die unless $pid;
			$parents->{r} = $pid;
			next;
		}
		if (s/^G:\s*//) {
			&$action($parents, $desc);

			$pid = find_hier('g', $_);
			if ($pid) {
				$action = \&add_nothing;
				$parents->{g} = $pid;
			} else {
				$action = \&add_goal;
			}
			next;
		}
		if (s/^[P]:\s*//) {
			&$action($parents, $desc);

			$action = \&add_project;
			set_option(Title => $_);
			$desc = '';
			next;
		}
		if (s/^\[_*\]\s*//) {
			&$action($parents, $desc);

			$action = \&add_action;
			set_option(Title => $_);
			$desc = '';
			next;
		}
		$desc .= "\n" . $_;
	}
	&$action($parents, $desc);
}

sub find_hier {
	my($type, $goal) = @_;

	for my $ref (Hier::Tasks::hier()) {
		next unless $ref->get_type() eq $type;
		next unless $ref->get_task() eq $goal;

		return $ref->get_tid();
	}
	for my $ref (Hier::Tasks::hier()) {
		next unless $ref->get_type() eq $type;
		next unless lc($ref->get_task()) eq lc($goal);

		return $ref->get_tid();
	}

	for my $ref (Hier::Tasks::hier()) {
		next unless $ref->get_task() eq $goal;
	
		my($type) = $ref->get_type();
		my($tid) = $ref->get_tid();
		warn "Found: something close($type) $tid: $goal\n";
		return $tid;
	}
	die "Can't find a hier item for '$goal' let alone a $type.\n";
}

sub add_nothing {
	# do nothing
}

sub add_goal {
	my($parents, $desc) = @_;
	my($tid);

	$desc =~ s/^\n*//s;

	$Parent = $parents->{'r'};
	$Type = 'g';

	$tid = add_task($desc);
	print "Added goal $tid: $desc\n";

	$parents->{'g'} = $tid;
}

sub add_project {
	my($parents, $desc) = @_;
	my($tid);

	$desc =~ s/^\n*//s;

	$Parent = $parents->{'g'};
	$Type = 'p';

	$tid = add_task($desc);
	print "Added project $tid: $desc\n";

	$parents->{'p'} = $tid;
}

sub add_action {
	my($parents, $desc) = @_;
	my($tid);

	$desc =~ s/^\n*//s;
	$Parent = $parents->{'p'};
	$Type = 'n';

	$tid = add_task($desc);
	print "Added task $tid: $desc\n";
}

1;  # don't forget to return a true value from the file
