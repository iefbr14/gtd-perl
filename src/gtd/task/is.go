package task

import "fmt"
import "regexp"
import "strconv"

var re_is_word = regexp.MustCompile("^[a-zA-Z]+$")
var re_is_task = regexp.MustCompile("^[0-9]+$")

func IsWord(word string) bool {
	return re_is_word.MatchString(word)
}

func IsTask(word string) bool {
	return re_is_task.MatchString(word)
}

func Lookup(tid string) *Task {
	re_is_task_colon := regexp.MustCompile("^[0-9]+:$")

	if re_is_task_colon.MatchString(tid) {
		tid = tid[:len(tid)-1]
	}
	if IsTask(tid) {
		i, err := strconv.Atoi(tid)
		if err != nil {
			fmt.Printf("invalid task id: %s", tid)
			return nil
		}
		return Find(i)
	}

	fmt.Printf("No such task: %s", tid)
	return nil
}
