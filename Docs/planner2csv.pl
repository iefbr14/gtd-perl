#!/usr/bin/perl -w

# Parse a .planner file from Planner and generate a CSV from it.
# For use with: http://live.gnome.org/Planner
#
# Written by: Andrew Ruthven <andrew@etc.gen.nz>
# Git repo: http://git.etc.gen.nz/planner-tools.git
#
# Released under the GPLv3.
#
# Usage: planner2csv.pl <file> > out.csv

use XML::LibXML;
use Text::CSV_XS;

my $file = shift;
if (-! -f $file) {
  die "Sorry, what file do you want to convert to a CSV?\n";
}

# Spit out UTF-8 in the output.
binmode STDOUT, ":utf8";

my $parser = XML::LibXML->new;
my $tree = $parser->parse_file($file);

my $root = $tree->getDocumentElement;

my $csv = Text::CSV_XS->new(); 
my %id_map;

my @headers = ('id', 'description', 'allocated', 'start', 'end', 'duration (s)', 'percent complete',
  'predecessor');
my %headers;
for my $i (0..$#headers) {
  $headers{$headers[$i]} = $i;
}

# Print out the headers line.
$csv->combine (@headers);
print $csv->string() . "\n";

my @rows;
for my $tasks ($root->findnodes('/project/tasks')) {
  find_tasks($tasks, \@rows);
}

# Go through all the rows and find any predecessors that refer to tasks
# later in the file.
for my $row (@rows) {
  $row->[$headers{'predecessor'}] =~ s/PARSE2:(\d+)/$id_map{$1}/;

  $csv->combine (@{ $row });
  print $csv->string() . "\n";
}


sub find_tasks {
  my $node = shift;
  my $rows = shift;
  my $level = shift || 0;
  my @id = @_;

  $id[$level] = 0;

  for my $task ($node->findnodes('task')) {
    $id[$level]++;
    my @fields = ();
    my $id = join('.', @id);
    $id_map{$task->findvalue('@id')} = $id;

    push @fields, $id,
        $task->findvalue('@name');
    push @fields, find_allocated($task);

    push @fields, 
        date_convert($task->findvalue('@start')),
        date_convert($task->findvalue('@end')),
        $task->findvalue('@work'),
        $task->findvalue('@percent-complete');

    push @fields, find_predecessors($task);

    push @rows, \@fields;

    push @id, '0';
    find_tasks($task, $rows, $level + 1, @id);
    pop @id;
  }
}

sub find_allocated {
  my $task = shift;

  my @resources = ();

  for my $allocation ($root->findnodes('/project/allocations/allocation[@task-id=' . $task->findvalue('@id') . ']')) {
    for my $resource ($root->findnodes('/project/resources/resource[@id=' . $allocation->findvalue('@resource-id') . ']')) {
      push @resources, $resource->findvalue('@name');
    }
  }

  return join(', ', @resources);
}

sub find_predecessors {
  my $task = shift;

  my @predecessors = ();

  for my $predecessor ($task->findnodes('predecessors/predecessor')) {
    my $id = $predecessor->findvalue('@predecessor-id');
    push @predecessors, ($id_map{$id} || "PARSE2:$id")  . ' ' 
      . $predecessor->findvalue('@type');
  }

  return join(', ', sort @predecessors);
}

sub date_convert {
  my $date = shift;

  $date =~ s/^(\d{4})(\d\d)(\d\d).*/$1-$2-$3/;

  return $date;
}
