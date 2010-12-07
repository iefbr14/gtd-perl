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
		&report_header &summary_line &dump_task 
		&meta_desc &type_disp &action_disp
		&lines &columns
	);
}

use Hier::Tasks;
use Hier::Selection;
use Hier::Filter;
use Hier::CCT;
use Hier::Option;

use POSIX qw(strftime);

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
	my($type) = uc($ref->get_type());

	return '<X>'     if $ref->is_ref_task() && $ref->get_completed();
	$type = '_'      if $ref->is_ref_task();

	return "<$type\>" if $ref->get_completed();
	
	return "}$type\{" if $ref->get_later();
	return "{$type\}" if $ref->get_isSomeday() eq 'y';
	return "[$type\]" if $ref->get_nextaction() eq 'y';
	return "($type\)";
}

sub action_disp {
	my($ref) = @_;

	my($key) = '[ ]';

	$key = '[_]' if $ref->get_nextaction() eq 'y';
	$key = '[*]' if $ref->get_completed();

	$key =~ s/.(.)./($1)/ 	if $ref->get_isSomeday() eq 'y';
	$key =~ s/.{.}./($1)/ 	if $ref->get_tickledate();
	$key =~ s/(.)./$1w/ 	if $ref->get_type() eq 'w';

	return $key;
}

#==============================================================================
sub dump_task {
	my ($ref) = @_;

	my($val);
	for my $key (sort keys %$ref) {
		$val = $ref->{$key} || '';
		$val =~ s/\n.*/.../m;
		print "$key:\t$val\n";
	}
}


sub delete_hier {
	die "###ToDo Broked, should be deleting by categories?\n";
	foreach my $tid (@_) {
		my $ref = Hier::Tasks::find{$tid};
		if (defined $ref) {
			print "Category $tid deleted\n";

			$ref->delete();

		} else {
			print "Category $tid not found\n";
		}
	}
}

sub is_hier {
	my($id) = @_;

	my $ref = Hier::Tasks::find{$id};
	return unless defined $ref;

	return unless $ref->is_ref_hier();
	return $ref;
		
}

# post process after loading tables;
sub metafix {
	my($tid, $pid, $p, $name, $only);

	$Debug = option('Debug');

	# Process Tasks (non-hier) items
	for my $ref (Hier::Tasks::all()) {
		$tid = $ref->get_tid();

		$only = $ref->{_todo_only};
		if ($only == 1) {	# only in todo (gtd deleted it)
			print "Need delete: $tid\n";
			dump_task($ref);
			$ref->delete();
			next;

		} elsif ($only == 2) {	# only in gtd (we fuck up somewhere)
			print "Need create: $tid\n";
			dump_task($ref);

		} elsif ($only == 3) {	# in both (happyness)

		} else {
			dump_task($ref) if option('Debug');
			die "We buggered up: $tid\n";
		}

#		$ref->set_priority(5) ||= 5  unless $ref->{isSomeday} eq 'y';

		$ref->{_actions} = 0;		# todo items
		$ref->{_child} = 0;		# hier items
	}
}

sub metacount {
	my($tid, $pid, $p, $name);

	# Process Tasks (non-hier) items
	foreach my $ref (Hier::Tasks::all()) {
		for my $pref ($ref->get_parents()) {
			if ($ref->is_ref_hier()) {
				$pref->{_child}++;
			} else {
				$pref->{_actions}++;
			}
		}
	}
}

sub min_key {
	my($hash) = @_;

	my(@list) = sort { $a <=> $b } keys %$hash;
	return undef unless @list;

	return $list[0];
}

sub report_header {
	return if option('List');

	my($title) = option('Title') || '';
	if (@_) {
		my($desc) = join(' ', @_) || '';

		if ($title and $desc) {
			$title .= ' -- ' . $desc;
		} elsif ($title eq '') {
			$title = $desc;
		}
	}

	my($cols) = columns() - 2;

	if (option('Html')) {
		print "<h1>$title</h1>\n";
	} elsif (option('Wiki')) {
		print "== $title ==\n";
	} else {
		print '#',"=" x $cols, "\n";
		print "#== $title\n";
		print '#',"=" x $cols, "\n";
	}
}

sub lines {
	my($lines) = $ENV{LINES} || 24;

	return $lines;
}

sub columns {
	my($rows) = $ENV{COLUMNS} || 80;

	return $rows;
}

sub summary_line {
	my($val, $sep, $ishtml) = @_;

	return '' unless $val;
	return '' if $val =~ /^\s*[.\-\*]/;

	$val =~ s/\n.*//s;
	$val =~ s/\r.*//s;

	if ($ishtml) {
		$val =~ s/&/\&amp;/g;
		$val =~ s/</&lt;/g;
		$val =~ s/>/&gt;/g;
		$val =~ s/"/&quote;/g;
	}

	return $sep . $val;
}
#==============================================================================
#==== filter setup and processing

sub meta_argv {
	local($_);

	my(@ret);

	Hier::Filter::add_filter_tags();
	while (scalar(@_)) {
		$_ = shift @_;
		if ($_ eq '!.') {
			print "Stopped.\n";
			exit 0;
		}

		if (s/^\@//) {
			Hier::Filter::meta_find_context($_);
			next;
		}
		if (s=^\/==) {				# pattern match
			add_pattern($_);
			next;
		}

		if (s/^\=//) {				# search for.
			add_selection($_);
			next;
		}
		if (s/^\*//) {
			my($type) = lc(substr($_, 0, 1));
			$type = type_name($_);
			print "Type ========($type)=:  $_\n";
			set_option(Type => $type);
			next;
		}
		if (s/^([A-Z])://) {
			my($type) = lc($1);
			set_option(Type => $type);

			print "Type: Title =====:  $type: $_\n";
			set_option(Title -> $_);
			next;
		}

		if (m/^[+~]/) {		# add include/exclude
			Hier::Filter::add_filters($_);
			next;
		}
#		if ($Title) {
#			print "Desc:  ", join(' ', $_, @_), "\n";
#			return join(' ', $_, @_);
#		}
		push(@ret, $_);
	}

	return @ret;
}

sub meta_desc {
	return join(' ', meta_argv(@_));
}

1; # <=============================================================
