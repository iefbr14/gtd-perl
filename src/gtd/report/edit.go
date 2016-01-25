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

import "fmt"
import "os"
import "os/exec"
import "log"
import "bufio"

import "regexp"

import "gtd/meta"
import "gtd/task"
import "gtd/display"

//-- Edit listed actions/projects
func Report_edit(args []string) int {
	meta.Filter("+all", "^tid", "dump")

	list := meta.Pick(args)
	if len(list) == 0 {
		fmt.Println("No items to edit")
		return 1
	}

	//? os.Umask(0077)

	change_map := map[string]*string{}

	tmpfile := fmt.Sprintf("/tmp/todo.%d", os.Getpid())

	ofd, err := os.Create(tmpfile) // For read access.
	if err != nil {
		log.Printf("%s", err)
		return 2
	}

	for _, t := range list {
		display.Dump(ofd, t)
	}
	err = ofd.Close()
	if err != nil {
		log.Fatal("I/O error on %s: %s", tmpfile, err)
		return 2
	}

	if err := exec.Command("vi", tmpfile).Run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	ifd, err := os.Open(tmpfile)
	if err != nil {
		log.Fatal("Can't reopen %s: %s", tmpfile, err)
		return 2
	}

	re_keyv := regexp.MustCompile(`^(\w+):\t\t?(.*)\s*$`)
	re_word := regexp.MustCompile(`(\w+)$`)
	re_plus := regexp.MustCompile(`^\t\t?(.*)`)

	scanner := bufio.NewScanner(ifd)
	for scanner.Scan() {
		line := scanner.Text()

		// skip blank and comment lines
		if task.Is_comment(line) {
			continue
		}

		if line == "=-=" {
			save(change_map)
			change_map = map[string]*string{}
			continue
		}

		// (m/^(\w+):\t\t?(.*)\s*$/)
		r := re_keyv.FindString(line)
		fmt.Printf("k %v", r)

		if len(r) > 0 {
			//key, val := r[0], r[1]
			//change_map[key] = val
			continue
		}

		// (m/^(\w+)$/)
		r = re_word.FindString(line)
		fmt.Printf("w %v", r)
		if len(r) > 0 {
			//key := r[0]
			//change_map[key] = nil
			continue
		}

		// (s/^\t+//)
		r = re_plus.FindString(line)
		fmt.Printf("t %v", r)
		if len(r) > 0 {
			//change_map[key] += "\n" + r[0]
			continue
		}
		panic("Can't parse: $_\n")
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}

	ifd.Close()

	if len(change_map) > 0 {
		save(change_map)
	}

	os.Remove(tmpfile)
	return 0
}

func save(change_map map[string]*string) {
	tid := change_map["todo_id"]

	t := meta.Find(*tid)

	changed := fmt.Sprintf("Saving %d - %s ...\n", tid, change_map["task"])

	u := 0

	for key, newval := range change_map {
		val := t.Get_KEY(key)

		// Specal values from disp_ordered_dump
		switch key {
		case "Tags":
			val = t.Disp_tags()
		case "Parents":
			val = t.Disp_parents()
		case "Children":
			val = t.Disp_children()
		}

		if val != "" && newval != nil {
			if val == *newval {
				continue
			}
			u++
			t.Set_KEY(key, *newval)

			changed += key + ": $val -> $newval\n"
			continue
		}
		if newval != nil { // val must be undefined
			u++
			t.Set_KEY(key, *newval)

			changed += key + ": set to " + *newval + "\n"
			continue
		}
		if val != "" { // newval must be undefined
			u++
			t.Set_KEY(key, "")

			changed += "$key: removed val $val\n"
			continue
		}
		// both undefined, don't care
	}

	if u == 0 {
		fmt.Printf("Item $tid unchanged\n")
		return
	}

	fmt.Print(changed)
	fmt.Print("Not UPDATED!!!\n")
	return
	t.Update()

	//***BUG*** check no extra keys returned?
	fmt.Print("Saved\n")
	return
}
