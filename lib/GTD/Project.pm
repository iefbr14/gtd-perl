package GTD::Project;

use strict;
use warnings;

use Carp;

our $VERSION     = 1.00;

use base qw(GTD::Hier GTD::Fields GTD::Filter);

my $Max_todo = 0; 	# Last todo id (unique for all tables)
my %Task;		# all Todo items (including Hier)

our $Resource;

sub new {
	my($class, $ref) = @_;

	my($self) = { 'object' => $ref };

	bless $self;

	###TODO load resource list from yaml
	return $self;
}

sub resource {
	my($self, $ref) = @_;

	$ref = $self->task() unless $ref;

	my($resource) = $ref->get_resource();
	return $resource if $resource;

	my($reason);
	($resource, $reason) = calc_resource($ref);

	$ref->hint_resource($resource);
	$ref->set_hint($reason);
	return $resource;
}

sub calc_resource {
	my($ref) = @_;

	my($resource) = $ref->get_resource();
	return ($resource, 'resource') if $resource;	# handle recursion

	my($type) = $ref->get_type();

	my($title) = $ref->get_title();
	my($context) = $ref->get_context();
	my($category) = $ref->get_category();
	my($desc) = $ref->get_description();

	if ($desc =~ /^allocate:(\S+)$/) {
		###TODO verify $1 in resource list
		return ($1, 'allocate');
	}

	if (defined $Resource->{category}{$category}) {
		return ($Resource->{category}{$category}, 'category');
	}
	if (defined $Resource->{context}{$context}) {
		return ($Resource->{context}{$context}, 'context');
	}
	if ($type eq 'g') {
		if (defined $Resource->{goal}{$title}) {
			return ($Resource->{goal}{$title}, 'goal');
		}
	}
	if ($type eq 'r') {
		if (defined $Resource->{role}{$title}) {
			return ($Resource->{role}{$title}, 'role');
		}
	}

	my(@tags) = $ref->get_tags();
	###TODO look up data in resource list

	# ok maybe the parent resource.
	my($pref) = $ref->get_parent();

	# nope, we are orfaned or top level;
	return ('personal', 'top') unless $pref;

	return calc_resource($pref);
}

sub task {
	my($self) = @_;

	return $self->{'object'};
}

sub hint {
	my($self) = @_;

	my($ref) = $self->task();
	return $ref->get_hint();
}

sub effort {
	my($self) = @_;

	my($effort) = $self->how();

	$effort =~ s/ \#.*//;
	return $effort;
}

sub how {
	my($self) = @_;

	my($ref) = $self->task();

	my($effort) = $ref->get_effort();
	if ($effort) {
		if ($effort eq '?') {
			$effort = '';
		} else {
			$effort .= 'h';
		}
	}

	my($type) = $ref->get_type();
	my($desc) = $ref->get_description();

	if ($desc =~ /^pages:(\d+)$/m) {
#		$effort =  int($1 / 30) . "h # $1 pages";
		$effort =  "1h # $1 pages";
	}
	if ($desc =~ /^effort:(\d+[hd])$/m) {
		$effort = $1;
	}

	if ($effort eq '') {
		###TODO have these in the resource list
		my(%efforts) = (
			Quick => '1h',
			Hour  => '2h',
			Day   => '8h',
			Week  => '5d',
			Month => '20d',
			Year  => '100d',
		);

		my $tf = $ref->get_timeframe() || '';
		if ($tf && defined $efforts{$tf}) {
			$effort = $efforts{$tf};
		} else {
			$effort = '1h # action';
			$effort = '2h # project needs planning' if $type eq 'p';
			$effort = '8h # goal need planning' if $type eq 'g';
		}
	}

	if ($type eq 'a') {
		return $effort;
	}

	if ($ref->count_children() == 0) {
		return $effort;
	}

	return $effort;
}

sub hours {
	my($self, $ref) = @_;

	$ref = $self->task() unless $ref;

	my($effort) = $self->effort();
	return 0 unless $effort;

	if ($effort =~ m/^([.\d]+)h.*$/) {
		return $1;
	}
	if ($effort =~ m/^([.\d]+)d.*$/) {
		return $1 * 4;
	}
	return $effort;
}

sub complete {
	confess("Unused fuction resource.complete");
}

# for each action, grouped by resource, sorted by priority/hier.task-id
# tag it as depending on the previous resource
sub predecessor {
	confess("Unused fuction resource.predecssor");
}

1;  # don't forget to return a true value from the file


