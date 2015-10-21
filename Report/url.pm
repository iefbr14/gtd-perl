package Hier::Report::url;

=head1 NAME

=head1 USAGE

=head1 REQUIRED ARGUMENTS

=head1 OPTION

=head1 DESCRIPTION

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE and COPYRIGHT

(C) Drew Sullivan 2015 -- LGPL 3.0 or latter

=head1 HISTORY

=cut

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &Report_url );
}

use Hier::util;
use Hier::Meta;
use Hier::Sort;
use Hier::Format;

our($Debug) = 0;

my(@Urls);
my($Host);

sub Report_url {	#-- quick List by various methods
	meta_filter('+g:live', '^title', 'task');	# Tasks filtered by goals

	my($title) = join(' ', @_);

	my(@list) = meta_pick(@_);
	if (@list == 0) {
		@Urls = ('Main_Page');
	}
	report_header('Tasks', $title);

	for my $ref (sort_tasks @list) {
		find_url($ref);
	}

	if (@Urls) {
		print '+ firefox ', join(' ', @Urls), "\n" if $Debug;
		unless ($ENV{'DISPLAY'}) {
			$Host = guess_remote();
		}
		if ($Host) {
			print "Displaying on $Host\n";
			system('ssh', $Host, 'DISPLAY=:0.0', 'firefox', @Urls);
		} else {
			system('firefox', @Urls);
		}
	} else {
		print "No urls found for @_\n";
	}
}

sub guess_remote {
	my $wholine = `who am i`;
	if ($wholine !~ m/\((.*)\)/) {
		die "Can't guess who for $wholine\n";
	}
	my($who) = $1;

	return "drugs.ss.org" if $who eq 'tofw.optical-online.com';
	return "drugs.ss.org" if $who eq 'silver.ss.org';
	return "rabbit" if $who eq 'fw.iplink.net';

	die "Can't map $who to remote site\n";
}

sub find_url {
	my($ref) = @_;
	
	my($line) = $ref->get_title();
	my($gtd_id) = $ref->get_tid();

	my @gtds = ( $gtd_id );
	my @urls = $line =~ /\[\[([\/:\w\s._\&\(\)]+)\]\]/g;

	my @cc_s = $line =~ /\{\{([\|\/:\w\s._\&]+)\}\}/g;
	for my $url (@cc_s) {
		my($cli,$proj) = split(/\|/, $url, 2);
		push(@urls, "CC $proj");
	}
		

	my($base) = "http://wiki.ss.org";
	if (@urls) {
		for my $match (@urls) {
			$match =~ s/ /_/g;
			push(@Urls, "$base/dev/index.php/$match");
		}
	}
	if (@gtds) {
		for my $id (@gtds) {
			push(@Urls, "$base/todo/r617/itemReport.php?itemId=$id");
		}
	}

	if ($Debug) {
		print "line: $line\n";
		print "gtd @gtds => wiki @urls\n";
	}
}

1;  # don't forget to return a true value from the file
