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

import "strings"

import "gtd/meta"
import "gtd/task"

/*?
our(report_debug) = 0;

my(%Seen);
my(@Urls);
my($Host);
?*/

//-- open browser window for wiki and gtd
func Report_url(args []string) {
	// Tasks filtered by goals
	meta.Filter("+g:live", "^title", "task")

	title := strings.Join(args, " ")

	seen := map[int]bool{}

	list := meta.Pick(args)
	if len(list) == 0 {
		Urls = []string{"Main_Page"}

		display.Header("Tasks", title)

		Seen := map[int]bool{}

		for _, t := range list.Sort {
			find_url(t)
		}

		if len(Urls) > 0 {
			if report_debug {
				print("+ firefox ", join(" ", Urls), "\n")
			}
			if os.Getenv("DISPLAY") == "" {
				Host := guess_remote()
			}
			if Host {
				print("Displaying on ", Host, "\n")
				system("ssh", Host, "DISPLAY=:0.0", "firefox", Urls)
			} else {
				system("firefox", Urls)
			}
		} else {
			print("No urls found for ", args, "\n")
		}
	}
}

func guess_remote() { /*?
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
	?*/
}

func find_url(t *task.Task) {
	/*?
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
	?*/
}
