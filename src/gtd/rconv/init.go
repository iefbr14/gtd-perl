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

//-- Init ~/.todo structure
func Report_init(args []string) int {
	home := os.Getenv("HOME")
	todo := home + "/.todo"

	
	  	unless (-d todo) {
	  		mkdir $todo, 0700 or panic("Can't mkdir $todo ($!)\n");
	  		print "mkdir $todo\n";
	  	}

	  	my($ini) = "$todo/Access.yaml";
	  	unless (-f $ini) {
	  		open(my $fh, '>", $ini) or panic("Can"t create $ini ($!)\n");
	  ?*/
fmt.Print(fh, `
gtd:
      host:      localhost
      dbname:    gtd
      user:      gtd
      pass:      gtd-time
      prefix:    gtd_
`)

fmt.Print(fh, `
  resource:
	      category:
	  	Where: personal
	      context:
	  	Context: personal
	      goal:
	          Golename: personal
	      role:
	          Rolename: personal
`)
	fh.Close()
	  		print("created $ini\n")
	  		print("Please set/verify the values in [gtd] section\n")
	  	}
	return 0
}
