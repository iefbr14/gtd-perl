package color

//? @EXPORT      = qw(&color &print_color &color_ref &nl);

import "fmt"
import "io"
import "os"
import "strings"

import "gtd/option"
import "gtd/task"

var Type = 0
var Incolor = false

var Pri_terminal = map[string]int {
	"NEXT"	: 1,
	"DONE"	: 9,
}

const ESC = "\027"

var Fg_terminal = map[string]string { 
	"BOLD":	"1",
	"STRIKE":	"9",

	"BLACK":	"0;30",
	"RED":		"0;31",
	"GREEN":	"0;32",
	"BROWN":	"0;33",		// dark yellow
	"NAVY":		"0;34",		// dark blue
	"PURPLE":	"0;35",	
	"CYAN":		"0;36",
	"GREY":		"0;37",
	"GRAY":		"0;37",
//light
	"SILVER":	"1;30",		// light black
	"PINK":		"1;31",		// light red
	"LIME":		"1;32",		// light green
	"YELLOW":	"1;33",		// light brown
	"BLUE":		"1;34",		
	"MAGENTA":	"1;35",		// light purple
	"AQUA":		"1;36",		// light cyan
	"WHITE":	"1;37",		// light grey :-)
	"NONE":		"0",
}

var Bg_terminal = map[string]string { 
	"BLACK":	"40", "BK":		"40",
	"RED":		"41",
	"GREEN":	"42",
	"BROWN":	"43",		// dark yellow
	"NAVY":		"44",		// dark blue
	"PURPLE":	"45",	
	"CYAN":		"46",
	"GRAY":		"47", "GREY":		"47",
//light
	"SILVER":	"40",		// light black
	"PINK":		"41",		// light red
	"LIME":		"42",		// light green
	"YELLOW":	"43",		// light brown
	"BLUE":		"44",		
	"MAGENTA":	"45",		// light purple
	"AQUA":		"46",		// light cyan
//	"WHITE":	"47",		// light grey :-)

	"WHITE":	"49",
	"NONE":		"0",
}


func Off() string {
	return FgBg("", "");
}

func On(fg string) string {
	return FgBg(fg, "");
}

func FgBg(fg, bg string) string {
	//## print "color: Type:Type Incolor:$Incolor\n";
	if (Type == 0) {
		guess_type();
	}

	if (Type == 1) {
		return "";
	}

	if (Type == 2) {
		color := ""

		if fg == "" {
			if Incolor {
				color = task.Join(ESC, "[0m")
			}
			Incolor = false;
			return color;
		}

		fg = strings.ToUpper(fg);
		bg = strings.ToUpper(fg);

		cv := Fg_terminal[fg];
		bv := Bg_terminal[bg];

		//print "$fg=>cv:$cv, $bg=>bv:$bv\n";

		if cv != "" {
			color = task.Join(ESC, "[", cv, "m")
		}
		if bv != "" {
			color = task.Join(ESC, "[", bv, "m")
		}
		Incolor = true;
		return color;
	}

	if (Type == 3) {
		color := ""
		if fg == "" {
			if Incolor {
				Incolor = false;
				return "</font>"
			}
			return ""
		}

		fg = strings.ToLower(fg);
		if Incolor {
			color = "</font>"
		}

		color = task.Join(color, "<font color=> ", fg, ">")
		Incolor = true;
		return color;
	}

	return ""
}

func print_color(fg string) {
	fmt.Print(On(fg))
}

func guess_type() {
	if (option.Get("Color", "guess") != "guess") {
		Type = 1
		return
	}

	if (os.Getenv("TERM") != "") {
		// fmt.Println("TERM: color mode TERM");

		Type = 2
		return
	} 

	if (os.Getenv("HTTP_ACCEPT") != "") {
		Type = 3
		return
	}

	// guess failed, no color
	Type = 1
}

// color.Ref displays the 
func Ref(ref *task.Task) {
	color_ref(ref, os.Stdout)
}

func color_ref(ref *task.Task, fd io.Writer) {
	if ref == nil {
		fmt.Fprint(fd, Off())
		return
	}
		
	fg := pick_color_fg(ref);
//	my($bg) = pick_color_bg($ref);
	bg := ""

	fmt.Fprint(fd, FgBg(fg, bg));
}

func pick_color_pri(ref *task.Task) string {

	if ref == nil {
		return ""
	}

	// pick context
	// pick pri
	// pick category


	if ref.IsNextaction {
		return "BOLD"
	}
	if ref.IsSomeday {
		return "YELLOW"
	}

	return ""
}

func pick_color_fg(ref *task.Task) string {
//?	return '' unless defined $ref;
	// pick context
	// pick pri
	// pick category

//	return "RED" if $ref->is_nextaction();
//?	return "GREY" if $ref->is_someday();
//?	return "STRIKE" if $ref->get_completed();

//?	my($pri) = $ref->get_priority();
//?	return "RED"   if $pri <= 1;
//?	return "PINK"  if $pri <= 2;
//?	return "GREEN" if $pri <= 3;
//?	return "BLACK" if $pri <= 4;
//?	return "CYAN"  if $pri > 4;

	return "";
}

func pick_color_bg(ref *task.Task) string {
//?	my($ref) = @_;

//?	return '' unless defined $ref;
	// pick context
	// pick pri
	// pick category

//	my($context) = uc($ref->get_context());

//	switch context {
//	"CC":	return "YELLOW" if $context eq 'CC';
//	"HOME:	return "RED"    if $context eq 'HOME';
//	"OFFICE":	return "BLUE"   if $context eq 'OFFICE';
//	"COMPUTER"
//	return "CYAN"   if $context eq 'COMPUTER';
//	return "PURPLE" if $context eq 'MAUREEN';
//	return "GREY"   if $context eq 'HOME';

	//return "YELLOW" if $ref->get_type eq 'm';	# Value
	//return "YELLOW" if $ref->get_type eq 'v';	# Vision
	//return "BLUE" if $ref->get_type eq 'o';	# Vision

	return "";
}

func Nl(fd io.Writer) {
	if fd == nil {
		fd = os.Stdout
	}

	color := Off();

	if Type == 3 {
		color = task.Join(color, "<br>");
	}

	fmt.Fprintln(fd, color)
}
