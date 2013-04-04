package Hier::util;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(
		&type_name &type_val &type_depth
		&type_disp &action_disp
		&lines &columns
	);
}

use Hier::Option;

my $Debug = 0;

my %Types = (
	'Value'		=> 'm',
	'Vision'	=> 'v',

	'Role'		=> 'o',
	'Goal'		=> 'g',

	'Project'	=> 'p',

	'Action'	=> 'a',
	'Inbox'		=> 'i',
	'Wait'		=> 'w',
	'Waiting'	=> 'w',

	'Reference'	=> 'r',

	'List'		=> 'L',
	'Checklist'	=> 'C',
	'Item'		=> 'T',
);
my %Type_name = ( reverse %Types );

sub type_val {
	my($val) = @_;
	return $val if defined $Type_name{val};

	my($type) = ucfirst($_[0]);


	if (defined $Types{$type}) {
		return $Types{$type};
	}
	if ($type =~ s/s$//) {
		if (defined $Types{$type}) {
			return $Types{$type};
		}
	}
	return '';
}

sub type_name {
	my($type) = @_;

	return $Type_name{$type};
}

sub type_depth {
	my($type) = @_;

	my %depth = (
		'm' => 1,		# hier
		'v' => 2,
		'o' => 3,
		'g' => 4,
		'p' => 5,

		'n' => 6,		# next actions
		'a' => 6,		# actions (tasks)
		'i' => 7,
		'w' => 7,
	);
	return $depth{$type};
}

sub type_disp {
	my($ref) = @_;
	my($type) = $ref->get_type();

	return '<X>'     if $ref->is_task() && $ref->get_completed();
	$type = '_'      if $ref->is_task();

	return "<$type\>" if $ref->get_completed();
	
	return "}$type\{" if $ref->is_later();
	return "{$type\}" if $ref->is_someday();
	return "[$type\]" if $ref->is_nextaction();
	return "($type\)";
}

sub action_disp {
	my($ref) = @_;

	return  '<*>' if $ref->get_completed();

	my($key) = '(_)';
	$key = '[_]' if $ref->is_nextaction();

	$key =~ s/.(.)./\}$1\{/	if $ref->is_later();
	$key =~ s/.(.)./\{$1\}/ if $ref->is_someday();
	$key =~ s/.(.)./\>$1\</	if $ref->get_type() eq 'w';

	return $key;
}

#==============================================================================

sub delete_hier {
	die "###ToDo Borked, should be deleting by categories?\n";
	foreach my $tid (@_) {
		my $ref = Hier::Tasks::find{$tid};
		if (defined $ref) {
			warn "Category $tid deleted\n";

			$ref->delete();

		} else {
			warn "Category $tid not found\n";
		}
	}
}

sub min_key {
	my($hash) = @_;

	my(@list) = sort { $a <=> $b } keys %$hash;
	return undef unless @list;

	return $list[0];
}



sub lines {
#	if (! -t *STDIN) {
#		return 60;
#	}
	my($lines) = $ENV{LINES} || 24;

	return $lines;
}

sub columns {
#	if (! -t *STDIN) {
#		return 80;
#	}
	my($rows) = $ENV{COLUMNS} || 80;

	return $rows;
}

1; # <=============================================================
