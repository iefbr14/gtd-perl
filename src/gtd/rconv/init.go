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

	status := os.Stat(todo)
	if !status.IsDir() {
		err := os.Mkdir(todo, 0700)
		if err != nil {
			panic("Can't mkdir $todo ($!)\n")
		}
		fmt.Printf("mkdir $todo\n")
	}

	ini := todo + "/Access.yaml"
	status := os.Stat(todo)
	if err != nil {
		fh, err := os.Create(ini)
		if err != nil {
			panic("Can't create $ini ($!)\n")
		}
		fmt.Fprintf(fh, "%s", `
gtd:
      host:      localhost
      dbname:    gtd
      user:      gtd
      pass:      gtd-time
      prefix:    gtd_
`)

		err := os.Close(fh)

	}
	ini := todo + "/Access.yaml"
	status := os.Stat(todo)
	if err != nil {
		fh, err := os.Create(ini)
		if err != nil {
			panic("Can't create $ini ($!)\n")
		}
		fmt.Fprintf(fh, "%s", `
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
		fmt.Print("created $ini\n")
		fmt.Print("Please set/verify the values in [gtd] section\n")
	}
	return 0
}
