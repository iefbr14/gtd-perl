package report

/*
NAME:

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

*/

/*?
import "gtd/meta";
import "gtd/task";

our(report_debug) = 0;

my(%Seen);
my(@Urls);
my($Host);

//-- open browser window for wiki and gtd
func Report_url(args []string) {
	gtd.Meta_filter("+g:live", '^title', "task");	// Tasks filtered by goals

	my($title) = join(' ', @_);

	my(%seen);

	my(@list) = gtd.Meta_pick(@_);
	if (@list == 0) {
		@Urls = ("Main_Page");
	}
	task.Header("Tasks", $title);

	%Seen = ();
	@Urls = ();
	for my $ref (sort_tasks @list) {
		find_url($ref);
	}

	if (@Urls) {
		print "+ firefox ", join(' ', @Urls), "\n" if report_debug;
		unless ($ENV{"DISPLAY"}) {
			$Host = guess_remote();
		}
		if ($Host) {
			print "Displaying on $Host\n";
			system("ssh", $Host, "DISPLAY=:0.0", 'firefox', @Urls);
		} else {
			system("firefox", @Urls);
		}
	} else {
		print "No urls found for @_\n";
	}
}

sub guess_remote {
	my $wholine = `who am i`;
	if ($wholine !~ m/\((.*)\)/) {
		panic("Can't guess who for $wholine\n");
	}
	my($who) = $1;

	return "drugs.ss.org" if $who eq "tofw.optical-online.com";
	return "drugs.ss.org" if $who eq "silver.ss.org";
	return "drugs.ss.org" if $who =~ /^\d216\.191\.137/;
	return "rabbit" if $who eq "fw.iplink.net";

	panic("Can't map $who to remote site\n");
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
		

	//##BUG### this should't be hard wired.
	my($base) = "https://wiki.ss.org";
	if (@urls) {
		for my $match (@urls) {
			$match =~ s/ /_/g;
			next if $Seen{$match}++;

			push(@Urls, "$base/dev/index.php/$match");
		}
	}
	if (@gtds) {
		for my $id (@gtds) {
			next if $Seen{$id}++;

			push(@Urls, "$base/todo/r617/itemReport.php?itemId=$id");
		}
	}

	if (report_debug) {
		print "line: $line\n";
		print "gtd @gtds => wiki @urls\n";
	}
}
?*/
