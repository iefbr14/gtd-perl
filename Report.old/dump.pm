package Hier::Report::dump;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &Report_dump &dump_ordered_ref &dump_ref );
}

use Hier::header;
use Hier::globals;
use Hier::util;
use Hier::sort;
use Hier::Tasks;

my @Order = (qw(
	todo_id
	type
	nextaction
	isSomeday
.
	task
	description
	note
.
	category
	context
	timeframe
.
	created
	doit
	modified
	tickledate
	due
	completed
	recur
	recurdesc
.
	owner
	palm_id
	priority
	private
.
) );

sub Report_dump {	#-- List all projects with actions
	add_filters('+all', '+any');	# everybody into the pool

	my($name) = ucfirst(meta_desc(@ARGV));	# some out
	if ($name) {
		if ($name =~ /^\d+/) {
			dump_list($name);
			return;
		}
		my($want) = type_val($name);
		unless ($want) {
			print "**** Can't understand Type $name\n";
			exit 1;
		}
		list_dump($want, $name);
		return;
	}
	list_dump('', 'All');
}

sub dump_list {
	my($list) = @_;

	my @list = split(/[^\d]+/, $list);
	my($ref);
	for my $tid (@list) {
		$ref = $Task{$tid};
		unless (defined $ref) {
			print "#*** No task: $tid\n";
			next;
		}
		dump_ordered_ref(\*STDOUT, $ref);
	}
}

sub list_dump {
	my($want_type, $typename) = @_;

	report_header($typename);

	my($pid, $ref, $proj, $type, $f, $kids, $acts);
	my($Dates) = '';

	# find all records.
	for my $tid (sort by_tid keys %Task) {
		$ref = $Task{$tid};

		$type = $ref->{type};
		next if $want_type && $type ne $want_type;

		next if filtered($ref);
	
		dump_ordered_ref(\*STDOUT, $ref);
	}
}

sub dump_ordered_ref {
	my($fd, $ref) = @_;

	my $val;
	for my $key (@Order) {
		next if $key =~ /^_/;
		if ($key eq '.') {
			print ".\n";
			next;
		}

		$val = $ref->{$key};
		if (defined $val) {
			chomp $val;
			$val =~ s/\r//gm;	# all returns
			$val =~ s/^/\t\t/gm;	# tab at start of line(s)
			$val =~ s/^\t// if length($key) >= 7;
			print $fd "$key:$val\n";
		} else {
			print $fd "#$key:\n";
		}
	}
	###BUG### handle missing keys from @Ordered
	print $fd "#Tags:\t", disp_tags($ref),"\n";
	print $fd "#Parents:\t", disp_parents($ref),"\n";
	print $fd "#Children:\t", disp_children($ref),"\n";
	print $fd "=-=\n\n";
}

sub dump_ref {
	my($fd, $ref) = @_;

	my $val;
	for my $key (sort keys %$ref) {
		next if $key =~ /^_/;

		$val = $ref->{$key};
		if (defined $val) {
			chomp $val;
			$val =~ s/\r//gm;	# all returns
			$val =~ s/^/\t\t/gm;	# tab at start of line(s)
			$val =~ s/^\t// if length($key) >= 7;
			print $fd "$key:$val\n";
		} else {
			print $fd "#$key:\n";
		}
	}
	print $fd "#Parents:\t", disp_parents($ref),"\n";
	print $fd "#Children:\t", disp_children($ref),"\n";
	print $fd "=-=\n\n";
}
1;  # don't forget to return a true value from the file
