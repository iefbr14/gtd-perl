default: build 

build:
	go build -o gtd-go gtd.go

run:
	./gtd-go search gtd-perl
	./gtd-go hier

install:
	cp gtd-go ../bin/gtd-go

#------------------------------------------------------------------------------
test:
	./gtd-go hier
	./gtd-go todo

board:
	./gtd-go kanban
	./gtd-go board 22

