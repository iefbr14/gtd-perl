sub hier_edit {
        my($tree, $path) = @_;

	my($ref) = $tree->infoData($path);
	my($tid) = $ref->get_tid();
print "Edit: $path => $tid\n";

        my($pkg) = {}; bless $pkg;

        my($w) = MainWindow->new();
        $pkg->{-mainWin} = $w;

#	$w->minsize(qw(200 200));
	$path =~ s/_\d+\./:/g;

	$w->title("GTD item $tid => $path");
	$w->configure(-background => 'cyan');

	Menu($pkg, $w,
                "Item", [
                        "Close",              \&connect,
                        "Abadon",              \&connect,
                        "Update",              \&connect,
                        "Save",              \&connect,
                        '-',
                        "Delete",              \&connect,
                        '-',
                        "Print",                \&print,
                ],
                "Quit", \&exit,
                "Help", [
                        "View HTML",    \&none,
                ],
        );

	my($t);
        $pkg->{-textWin} = $t = $w->Scrolled('Text',
                -width => 80,
                -height => 20,
        )->pack;
        $t->bind("<KeyPress>", [\&html_text::key, Ev('A')]);

        # Fill the textbox with a list of all the files in the directory.

        $t->bind('<Button-3>' => sub {
                my($l) = @_;

                print "button-3: l=$l\n";
                $pkg->view;
            }
        );

	my($val);
	foreach my $key (sort keys %$ref) {
		next if $key =~ /^_/;

		$val = $ref->{$key};
		next unless defined $val;

		$val =~ s/\r/\n/g;

		 $t->insert('insert', "$key\t\t$ref->{$key}\n");
	}
	$t->see("insert");

}
