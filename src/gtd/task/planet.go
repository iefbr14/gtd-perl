package main

import (
	"log"
	"reflect"
	"sort"
)

func test(planets []Planet) {
	log.Println("Sort Name")
	By(Prop("Name", true)).Sort(planets)
	log.Println(planets)

	log.Println("Sort Aphelion")
	By(Prop("Aphelion", true)).Sort(planets)
	log.Println(planets)

	log.Println("Sort Perihelion")
	By(Prop("Perihelion", true)).Sort(planets)
	log.Println(planets)

	log.Println("Sort Axis")
	By(Prop("Axis", true)).Sort(planets)
	log.Println(planets)

	log.Println("Sort Radius")
	By(Prop("Radius", true)).Sort(planets)
	log.Println(planets)
}

func Prop(field string, asc bool) func(p1, p2 *Planet) bool {
	return func(p1, p2 *Planet) bool {

		v1 := reflect.Indirect(reflect.ValueOf(p1)).FieldByName(field)
		v2 := reflect.Indirect(reflect.ValueOf(p2)).FieldByName(field)

		ret := false

		switch v1.Kind() {
		case reflect.Int64:
			ret = int64(v1.Int()) < int64(v2.Int())
		case reflect.Float64:
			ret = float64(v1.Float()) < float64(v2.Float())
		case reflect.String:
			ret = string(v1.String()) < string(v2.String())
		}

		if asc {
			return ret
		}
		return !ret
	}
}

type Planet struct {
	Name       string  `json:"name"`
	Aphelion   float64 `json:"aphelion"`   // in million km
	Perihelion float64 `json:"perihelion"` // in million km
	Axis       int64   `json:"Axis"`       // in km
	Radius     float64 `json:"radius"`
}

type By func(p1, p2 *Planet) bool

func (by By) Sort(planets []Planet) {
	ps := &planetSorter{
		planets: planets,
		by:      by, // The Sort method's receiver is the function (closure) that defines the sort order.
	}
	sort.Sort(ps)
}

type planetSorter struct {
	planets []Planet
	by      func(p1, p2 *Planet) bool // Closure used in the Less method.
}

// Len is part of sort.Interface.
func (s *planetSorter) Len() int { return len(s.planets) }

// Swap is part of sort.Interface.
func (s *planetSorter) Swap(i, j int) {
	s.planets[i], s.planets[j] = s.planets[j], s.planets[i]
}

// Less is part of sort.Interface. It is implemented by calling the "by" closure in the sorter.
func (s *planetSorter) Less(i, j int) bool {
	return s.by(&s.planets[i], &s.planets[j])
}

func main() {
	test(dataSet())
}

func dataSet() []Planet {

	var mars = new(Planet)
	mars.Name = "Mars"
	mars.Aphelion = 249.2
	mars.Perihelion = 206.7
	mars.Axis = 227939100
	mars.Radius = 3389.5

	var earth = new(Planet)
	earth.Name = "Earth"
	earth.Aphelion = 151.930
	earth.Perihelion = 147.095
	earth.Axis = 149598261
	earth.Radius = 6371.0

	var venus = new(Planet)
	venus.Name = "Venus"
	venus.Aphelion = 108.939
	venus.Perihelion = 107.477
	venus.Axis = 108208000
	venus.Radius = 6051.8

	return []Planet{*mars, *venus, *earth}
}
