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
import "sort"
import "strconv"
import "strings"

import "gtd/cct"
import "gtd/meta"
import "gtd/display"
import "gtd/color"

type cct_count_T struct {
	name  string
	sub   map[string]map[byte]int
	tot   map[string]int
	total int
}

func new_CCT(name string) cct_count_T {
	cct := cct_count_T{
	//		tot: map[string]int{},
	//		sub: map[string]map[byte]int{},
	}
	cct.name = name
	cct.tot = make(map[string]int)
	cct.sub = make(map[string]map[byte]int)
	return cct
}

//-- List Categories/Contexts/Time Frames
func Report_cct(args []string) int {
	meta.Filter("+all", "^tid", "simple")

	category := new_CCT("Category")
	context := new_CCT("Context")
	timeframe := new_CCT("Timeframe")
	tags := new_CCT("Tags")

	list := meta.Pick(args)
	if len(list) == 0 {
		list = meta.Selected()
	}
	for _, t := range list {
		kind := t.Type

		// types[kind]++

		cct_count_item(&category, kind, t.Category)
		cct_count_item(&context, kind, t.Context)
		cct_count_item(&timeframe, kind, t.Timeframe)

		//cct_count_item(&category, kind, "total")
		//cct_count_item(&context, kind, "total")
		//cct_count_item(&timeframe, kind, "total")

		for _, tag := range t.Tags {
			cct_count_item(&tags, kind, tag)
		}

	}

	cct_report_counts("Categories", category)
	cct_report_counts("Contexts", context)
	cct_report_counts("Time Frames", timeframe)
	cct_report_counts("Tags", tags)

	return 0
}

func cct_count_item(counts *cct_count_T, kind byte, value string) {
	if value == "" {
		value = "{no-cct}"
	} else {
		counts.total++
	}

	counts.tot[value]++
	if _, ok := counts.sub[value]; !ok {
		counts.sub[value] = make(map[byte]int)
	}
	counts.sub[value][kind]++
}

func itoz(i int) string {
	if i == 0 {
		return ""
	}
	return strconv.Itoa(i)
}

func Keys(m map[string]int) []string {
	slice := make([]string, 0, len(m))
	for key, _ := range m {
		slice = append(slice, key)
	}
	sort.Strings(slice)
	return slice
}

func cct_report_counts(header string, counts cct_count_T) {
	tot := 0
	for _, v := range counts.tot {
		tot += v
	}

	display.Header(header + " -- " + itoz(counts.total) + " of " + itoz(tot))

	keys := Keys(counts.tot)

	cct_ref := cct.Use(counts.name)
	color.Print("BOLD")
	fmt.Print("Val  Vis  Role Goal Proj Action Total Id: header Name")
	display.Nl()

	dups := map[string]int{}
	for _, key := range keys {
		cnt := 0
		for _, kind := range "mvogpa" {
			sk, ok := counts.sub[key][byte(kind)]
			if ok {
				cnt += sk
				fmt.Printf("%4d ", sk)
			} else {
				fmt.Printf("%4s ", "")
			}
		}

		id := itoz(cct_ref.Id(key))

		lc_key := strings.ToLower(key)
		dup := ':'
		if _, ok := dups[lc_key]; !ok {
			dups[lc_key]++
			dup = '*'
		}

		fmt.Printf("= %4d  %2s%c %s\n", cnt, id, dup, key)
	}
}
