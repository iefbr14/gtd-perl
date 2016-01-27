package gtd

import "fmt"

import "github.com/chzyer/readline"

import "gtd/task"

var prompt_Debug bool

var Term *readline.Instance

var Mode int // 0 - unknown
// 1 - file input
// 2 - term input

func Prompt(prompt string, ignore_comments bool) (string, error) {
	init_mode()
	if Mode == 2 {
		Term.SetPrompt(prompt)
	}

	for {
		var line string
		var err error

		switch Mode {
		case 1:
		//	$_ = <STDIN>;

		//	return unless defined $_;

		//	chomp $_;
		case 2:
			line, err = Term.Readline()
			if err != nil { // io.EOF
				fmt.Print(":quit # eof\n")
				return "", err
			}
		}
		//$_ = $Term->readline($prompt.' ');

		//? print "Prompt($prompt) read: $_\n" if $Debug;

		if ignore_comments {
			if task.Is_comment(line) {
				continue
			}
		}

		if Mode == 1 {
			fmt.Printf("%s\t%s\n", prompt, line)
			//		} else {
			//		$term->addhistory($_);
		}
		return line, nil
	}
}

func init_mode() {
	if Mode > 0 {
		return
	}

	if Mode == 0 { //if (-t STDIN)
		Mode = 2
		//Term = Term::ReadLine->new("gtd");
		Term, err := readline.New("> ")
		if err != nil {
			panic(err)
		}
	} else {
		Mode = 1
	}
}
