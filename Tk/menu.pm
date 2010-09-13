#!/usr/bin/perl -w
#
# fm -- File Manager
#
# $Id: fm,v 1.10 1996/06/14 03:29:31 drew Exp $
# $Source: /g/linux/tkperl/lib/RCS/fm,v $
#
use strict;

use Tk;

$main::opt_b = 0;
$main::opt_r = '';
&Getopts("r:b") || die "Usage: fm [-b] [-r{root-dir}] [dirlist]\n";
&gif_opt_set('KEEP', $main::opt_r) if $main::opt_r ne '';


&kick_start();
&Tk::MainLoop();

sub kick_start {
	if (@ARGV) {
		&fm::init('.', @ARGV);
	} else {
		&fm::init('.', <n[0-9]*>);
	}
}


package fm;

use Tk;

use ss::tk::fixup;
use ss::tk::help;
use ss::tk::menu;
use ss::tk::list;

sub init {
	my($dir, @files) = @_;
	my($file, $width);

	my($w) = new_win();
	$w->title("Directories");
	$w->geometry("=-0+0");

	my($pkg) = {
		-mainWin  => $w,
		-dirName  => $dir,
		-openFunc => \&fm::show,
	};
	bless $pkg;

	Menu($pkg, $w,
		"File", [
			"open", 		\&ss::list::open,
			'-',
			"filev",   		[ \&ss::list::apply, \&filev_one ],
			'-',
			"quit",			\&quit,
		],
		"Edit", [
			'top',			\&ss::list::top,
			"bottom", 		\&ss::list::later,
			'forget',		\&ss::list::next,
		],
		"Reports", [
			"decoderen",   		[ \&ss::list::apply, \&run, '(gsub|decoderen)' ],
			'-',
			"gg&d",    		[ \&ss::list::apply, \&run, '(gsub|decoderen;dgrope;grope) &' ],
		],
		"Help", [
			"Help File",		[ \&help, 'file',     ],
			"Help Commands",	[ \&help, 'commands', ],
			"Help Buttons",		[ \&help, 'buttons',  ],
			"Help Other",		[ \&help, 'other',    ],
		]
	);
	$width = 10;
	foreach $file (@files) {
		$file =~ s=/*$==;

		$width = length($file) if $width < length($file);
	}
	$pkg->{-nameWidth} = $width;

	&ss::list::new($pkg, @files);
}

sub browse_one {
	my($pkg, $dir, $item) = @_;

	warn "fm::browse($dir)\n";

	&browse($pkg, $dir);
}

sub filev_one {
	my($pkg, $dir, $item) = @_;

	warn "fm::filev($dir)\n";

	&filev($dir);
}

sub rescan {
	my($pkg) = @_;
	my($l) = $pkg->{-listWin};
	my($file);

	while ($l->size()) {
		$l->delete(0);
	}
	foreach $file (<n[0-9][0-9]>) {
		$l->insert("end", show_dir($pkg, $file, $file));
	}
}

sub quit {
	&view_kill;
	exit 0;
}

sub run {
	my($pkg, $dir, $item, $cmd) = @_;

	warn "+ cd $dir && $cmd\n";
	system("cd $dir && $cmd");
}

sub keep {
	my($pkg, $dir, $item) = @_;

	return -d $dir ? show_dir($pkg, $dir, $item) : undef;
}

sub show_dir {
	my($pkg, $file, $item) = @_;
	my($width) = $pkg->{-nameWidth};

	$item =~ s/\s.*//;
	my($nlink, $size) = (stat($file))[3,7];

	return sprintf("%-${width}s   %2d %5dk", $item, $nlink, $size / 1024);
}

sub show {
	my($pkg, $dir, $item) = @_;
	my($f);

	return undef unless -d $dir;

	return $item unless &ss::list::is_registered_top($pkg);

	$f = &filev($dir, ());
	return $item if defined $f;
	warn "No images in $dir\n";
		
	return undef if ($main::opt_b);

	$f = &browse($pkg, $dir);
	return $item if defined $f;
	warn "No files in $dir\n";

	clean($pkg, $dir);
	return undef unless -d $dir;

	$f = &browse($pkg, $dir);
	return $item if defined $f;

	$f = &filev($dir, ());
	return $item;
}
