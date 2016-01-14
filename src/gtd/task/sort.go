package task

//?	@EXPORT      = qw(sort_mode sort_tasks by_task by_goal by_goal_task )

import "fmt"
import "sort"
import "regexp"
import "strings"

import "gtd/option"

var sort_reverse = true

var by_sort func(a, b *Task) bool = by_tid

func (slice Tasks) Len() int {
	return len(slice)
}

func (slice Tasks) Less(i, j int) bool {
	if sort_reverse {
		return by_sort(slice[j], slice[i])
	} else {
		return by_sort(slice[i], slice[j])
	}
}

func (slice Tasks) Swap(i, j int) {
	slice[i], slice[j] = slice[j], slice[i]
}

func (slice Tasks) Sort() Tasks {
	sort.Sort(slice)
	return slice
}

var sort_Criteria = map[string]func(*Task, *Task) bool{
	"id":    by_tid,
	"tid":   by_tid,
	"task":  by_task,
	"title": by_task,

	"hier": by_hier,

	"pri":      by_pri,
	"priority": by_pri,
	"panic":    by_panic,
	"focus":    by_focus,

	"age":  by_age, // created date
	"date": by_age, // ''

	"change": by_change, // modified date

	"doit":     by_doitdate,
	"doitdate": by_doitdate,

	"status": by_status,

	"goal":     by_goal,
	"rgpa":     by_goal_task,
	"goaltask": by_goal_task,
}

var sort_cache_map = map[int]string{}
var sort_title_map = map[int]string{}

func Sort_invalidate_key(t *Task) {
	tid := t.Tid

	delete(sort_cache_map, tid)
	delete(sort_title_map, tid)
}

func Sort_mode(mode string) {
	if mode == "" {
		by_sort = by_task
		return
	}

	switch mode[0] {
	case '^':
		mode = mode[1:]
		sort_reverse = false
	case '~':
		mode = mode[1:]
		sort_reverse = true
		option.Set("Reverse", "1")
	}

	mode = strings.ToLower(mode)

	if f, ok := sort_Criteria[mode]; ok {
		by_sort = f

		// clear any cached keys
		sort_cache_map = map[int]string{}
		sort_title_map = map[int]string{}
		return
	}

	fmt.Printf("Unknown Sort mode: %s\n", mode)
}

func by_tid(a, b *Task) bool {
	return a.Tid < b.Tid
}

func by_hier(a, b *Task) bool {
	pa := a.Parent()
	pb := b.Parent()

	switch {
	case pa != nil && pb != nil:
		if pa != pb {
			return by_hier(pa, pb)
		}

	case pa != nil:
		return true

	case pb != nil:
		return false
	}

	// no parents or parents equal
	return lc_title(a) < lc_title(b) ||
		a.Tid < b.Tid
}

func by_status(a, b *Task) bool {
	ac := a.Completed
	bc := b.Completed

	if ac != "" && bc != "" {
		return ac < bc
	}

	// a completed but not b, sort early
	if ac != "" {
		return true
	}

	// b completed but not a, sort later
	if bc != "" {
		return false
	}

	return by_change(a, b)
}

func by_change(a, b *Task) bool {
	return a.Modified < b.Modified
}

func by_age(a, b *Task) bool {
	return a.Created < b.Created
}

func by_Task(a, b *Task) bool {
	return by_task(a, b) || by_tid(a, b)
}

func by_task(a, b *Task) bool {
	return lc_title(a) < lc_title(b)
}

func by_pri(a, b *Task) bool {
	// order by priority $order, created $order, due $order

	return a.Priority < b.Priority ||
		a.Created < b.Created ||
		a.Due < b.Due
}

func by_doitdate(a, b *Task) bool {
	return sort_doit(a) < sort_doit(b)
}

func sort_doit(t *Task) string {
	if v, ok := sort_cache_map[t.Tid]; ok {
		return v
	}

	v := t.Doit
	if v == "" {
		v = t.Created
	}

	sort_cache_map[t.Tid] = v
	return v
}

func by_goal(a, b *Task) bool {
	return sort_goal(a) < sort_goal(b)
}

func sort_goal(t *Task) string {
	tid := t.Tid

	if v, ok := sort_cache_map[tid]; ok {
		return v
	}

	list := make([]string, 0, 5)
	for {
		//? list = append(list, lc_title(t), tid)
		list = append(list, lc_title(t))

		if t.Type == 'g' {
			break
		}
		t = t.Parent()
		if t == nil {
			break
		}
	}

	v := strings.Join(list, "\t")
	sort_cache_map[tid] = v

	return v
}

func by_goal_task(a, b *Task) bool {
	return sort_goal_task(a) < sort_goal_task(b)
}

func sort_goal_task(t *Task) string {

	tid := t.Tid

	if val, ok := sort_cache_map[tid]; ok {
		return val
	}

	title := lc_title(t)

	p_title := "--"
	g_title := "--"

	p_ref := t.Parent()
	if p_ref != nil {
		p_title = lc_title(p_ref)
		g_ref := p_ref.Parent()
		if g_ref != nil {
			g_title = lc_title(g_ref)
		}
	}

	//? val := Join(g_title, "\t", p_title, "\t", title, tid)
	val := Join(g_title, "\t", p_title, "\t", title)
	sort_cache_map[tid] = val
	return val
}

// next   norm  some  done
// 012345 12345 12345
//  abcde fghij klmno z

func item_focus(t *Task) string {
	if t == nil {
		return ""
	}

	pri := t.Priority

	switch {
	case t.Is_nextaction():
		// cool	1-5  == abcde
	case t.Is_someday():
		pri += 10 // slow 11-15 == jklmn
	default:
		pri += 5 // ok    6-10 == fghij
	}

	if pri < 1 {
		pri = 1
	}
	if pri > 15 {
		pri = 15
	}

	// convert pri (int 1 to 15) to string val "a"..."o"
	val := string([]byte{byte(int('a') + pri - 1)})

	if t.Is_completed() {
		val = "z"
	}

	return val
}

func calc_focus(t *Task) string {
	if t == nil {
		return ""
	}
	tid := t.Tid

	if val, ok := sort_cache_map[tid]; ok {
		return val
	}

	pri := item_focus(t)

	val := calc_focus(t.Parent()) + pri
	sort_cache_map[tid] = val

	return val
}

func by_focus(a, b *Task) bool {
	return calc_focus(a) < calc_focus(b)
}

// next   norm  some  done
// 012345 12345 12345
//  abcde fghij klmno z

func calc_panic(t *Task) string {
	tid := t.Tid

	if val, ok := sort_cache_map[tid]; ok {
		return val
	}

	val := item_focus(t)
	for _, child := range t.Children {
		pri := calc_panic(child)
		if pri < val {
			val = pri
		}
	}

	sort_cache_map[tid] = val

	return val
}

func by_panic(a, b *Task) bool {

	ca := calc_panic(a)
	cb := calc_panic(b)
	if ca == cb {
		return by_hier(a, b)
	}
	return ca < cb
}

func lc_title(t *Task) string {
	tid := t.Tid

	// cache titles to make sorting by it O(n)
	if title, ok := sort_title_map[t.Tid]; ok {
		return title
	}

	// lower case it.
	title := strings.ToLower(t.Title)

	// strip bracket in [[wiki-ref]] => wiki-ref
	re := regexp.MustCompile(`\[\[`)
	title = re.ReplaceAllLiteralString(title, "")

	re = regexp.MustCompile(`\]\]`)
	title = re.ReplaceAllLiteralString(title, "")

	// fmt.Printf("lc_title: %s\n    =>  : %s\n", t.Title, title);

	sort_title_map[tid] = title
	return title
}
