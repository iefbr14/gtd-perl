package Hier::Resource;

use strict;
use warnings;

our $VERSION     = 1.00;

use base qw(Hier::Hier Hier::Fields Hier::Filter);

my $Max_todo = 0; 	# Last todo id (unique for all tables)
my %Task;		# all Todo items (including Hier)

sub new {
	my($class, $ref) = @_;

	my($self) = { 'object' => $ref };

	bless $self;

	###TODO load resource list from yaml
	return $self;
}

sub resource {
	my($self, $ref) = @_;

	my($role) = $ref->get_resource();
	return $role if $role;

	$role = calc_resource($ref);
	if ($role) {
		$ref->hint_resource($role);
		return $role;
	}

	$role = $self->resource($ref->get_parent());
	$ref->hint_resource($role);
	return $role;
}

sub calc_resource {
	my($ref) = @_;

	my($type) = $ref->get_type();

	if ($type eq 'm') {
		return 'personal';
	}

	my($title) = $ref->get_title();
	my($context) = $ref->get_context();
	my($category) = $ref->get_category();
	my($desc) = $ref->get_description();

	if ($desc =~ /^allocate:(\S+)$/) {
		###TODO verify $1 in resource list
		return $1;
	}

	my(@tags) = $ref->get_tags();
	###TODO look up data in resource list

	return;
}

sub effort {
	my($self, $ref) = @_;

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
		$effort =  int($1 / 30) . "h # $1 pages";
	}
	if ($desc =~ /^effort:(\d+[hd])$/m) {
		$effort = $1;
	}

	if ($effort eq '') {
		###TODO have these in the resource list
		my(%efforts) = (
			Quick => '0.3h',
			Hour  => '1h',
			Day   => '4h',
			Week  => '5d',
			Month => '20d',
			Year  => '60d',
		);

		my $tf = $ref->get_timeframe() || '';
		if ($tf && defined $efforts{$tf}) {
			$effort = $efforts{$tf};
		} else {
			$effort = '2h';
		}
	}

#	my $a = $ref->count_actions();
#	my $c = $ref->count_children();
#	print "# t=$type a=$a c=$c e=$effort\n";

	if ($type eq 'a') {
		return $effort;
	}

	if ($type eq 'p') {
		if ($ref->count_actions() > 0) {
			return;
		}
		if ($ref->count_children() > 0) {
			return;
		}
		return $effort;
	}

	if ($ref->count_children() == 0) {
		return $effort;
	}

	return;
}

# for each action, grouped by resource, sorted by priority/hier.task-id
# tag it as depending on the previous resource
sub predecessor {

}


1;  # don't forget to return a true value from the file


