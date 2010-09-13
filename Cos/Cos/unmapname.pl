sub unmapname {
	my($name) = @_;

	my($lab, $user, $lab, $cust, $month, $day, $s1, $s2);
	my($seq);

	$name =~ s=.*\/==;

#                                     month  day
#                  lab   user   ---  cust |  |  s1    s2
	$name =~ /^(\d+)-(\d+):(...)(...)(.)(.)(..)\.(.)./;
#                  1     2     3    4    5  6  7     8

	($lab, $cust, $sublab, $user, $month, $day, $s1,$s2) = ($1,$2, $3,$4, $5,$6, $7,$8);

	return $lab, $cust, $...

	$month = index('123456789ABC', uc($month));
	$day   = index('123456789ABCDEFGHIJKLMNOPQRSTUV', uc($day));

	return ($lab, $cust, $month, $day, $s1 . $s2);
}

# old shell encoder:
#
#	FILES=`find . -name '[0-9][0-9]*.[rR]'`
#	
#	if [ "x" != "x$FILES" ]
#	then
#	   for fnam in [0-9][0-9]*.[rR]
#	   do
#	      onam=`expr substr $fnam 1 12`
#	      lab=`expr substr $fnam 1 2`
#	      cust=`expr substr $fnam 3 3`
#	      month=`expr substr $fnam 6 2`
#	      day=`expr substr $fnam 8 2`
#	      seq_p1=`expr substr $fnam 10 1`
#	      seq_p2=`expr substr $fnam 11 2`
#	
#	    newnam="$lab$cust$emonth$eday$seq_p1.$seq_p2"
#	    mv $onam.[Rr] $newnam"r"
#	    if [ -f $onam".D" -o -f $onam".d" ]
#	    then
#	        mv $onam.[Dd] $newnam"d"
#	    fi
#	    if [ -f $onam".T" -o -f $onam".t" ]
#	    then
#	        mv $onam.[Tt] $newnam"t"
#	    fi
#	  done;
#	fi
