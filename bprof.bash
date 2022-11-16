#!/bin/bash
#

# disable PS4 for ourselves
# this implies we cannot be profiled by ourselves either!!!
#PS4=''
cumtm=0		# cumulative time
prev=0		# previous line
cnt=0		# count of calls

# can we make a simple plot?
if which feedgnuplot ; then PLOT=yes ; fi

# this will set the prompt to show time and line number (assuming GNU date)
#
# get the name of the script to be run
script=$1
shname=${script%.*}	# remove from last dot to end
pipename=`mktemp -u bprof.XXXXXXXXX -p .`	# or $(mktemp -u etc.)
#pipename=bprof.step1
echo "line	count	time	command" > $shname.bprof

if ! mkfifo -m 600 "$pipename" ; then 
    echo "Error: could not create temporary pipe $pipename"
    echo "       could someone be doing some mischief?"
#    exit
else
    echo "$pipename (OK)"
fi
# OK, run the script recording times
#set +x
(
    echo "Running $script"
    # save starting time
    date "+%s.%N	(0) " > $pipename
    # run logging command start times
    #PS4='$(date "+%s.%N	($LINENO) " )' bash -x $@ 
    PS4="\$(date \"+%s.%N	(\$LINENO) \" >> $pipename )" bash -xv $@ 
    # add a sentinel to signal end of logging
    date "+%s.%N	(end) " > $pipename >> $pipename
    exit
) &

echo "Processing $pipename"
# Process the timing output
# The pipe is open and closed on each command, so we need to 
tail -f -n +1 $pipename \
| while read tm ln trail; do
    # compute duration of each line execution
    ln=`echo $ln | tr -d '()'`
    if [ "$ln" = "0" ] ; then
    	# no output needed, placeholder for starting time
        prevtm=$tm
	prevln=$ln
	continue
    fi
    # this command starts after the last ends, so delta is that of the last
    delta=$(echo "$tm - $prevtm" | bc -l)
    txt=''
    echo "$prevln	$delta	$txt"
    prevtm=$tm
    prevln=$ln
    # keep the sentinel for subsequent processing
    if [ "$ln" = "end" ] ; then echo "9999999999	0"; break ; fi
    
done \
| sort -n \
| while read ln tm trail ; do
    if [ "$ln" = "$prev" ] ; then
        cumtm=`echo "$cumtm + $tm" | bc -l`
	cnt=$(( cnt + 1 ))
    else
        # new line, print previous and reset counters
        txt=`head -$prev $script | tail -1`
        echo "$prev	$cnt	$cumtm	$txt"
	cumtm=$tm
	cnt=1
    fi
    prev=$ln
done \
>> $shname.bprof

# remove pipe (no longer needed)
rm $pipename

# add plots if feedgnuplot is installed

if [ "$PLOT" = "yes" ] ; then
    # read column names
    read cx c0 c1 c2 <<< $(head -1 test.bprof)
    #
    cat $shname.bprof \
    | cut -f1,2,3 \
    | tail -n +2 \
    | feedgnuplot --domain \
        --unset grid \
        --lines --points \
	--title "Profile of $script" \
	--legend 0 "$c0" --legend 1 "$c1" \
	--xlabel "$cx" \
	--ylabel "$c0" --style 0 'linewidth 3'\
	--y2 1 --y2label "$c1" -style 1 'linewidth 3' \
	--xmin 0 --ymin 0 --y2min 0 \
	--terminal 'dumb 80,24' \
	--exit
    
    # get user onfirmation allowing for editing (-e)
    read -e -p "Do you want a copy of the plot [Y/n]? " yn
    # get only first letter
    yn=${yn:0:1}
    # make yn lowercase and test for empty or 'y'
    if [ -z "$yn" -o "${yn,,}" = 'y' ] ; then
        cat $shname.bprof \
	| cut -f1,2,3 \
	| tail -n +2 \
	| feedgnuplot --domain \
            --unset grid \
            --lines --points \
	    --title "Profile of $script" \
	    --legend 0 "$c0" --legend 1 "$c1" \
	    --xlabel "$cx" \
	    --ylabel "$c0" --style 0 'linewidth 3'\
	    --y2 1 --y2label "$c1" --style 1 'linewidth 3' \
	    --xmin 0 --ymin 0 --y2min 0 \
	    --hardcopy $shname.png \
	    --exit

	display $shname.png
    fi
 fi

exit
#
# on BASH 5 one may use to get the time in microseconds
#
#PS4='+ $EPOCHREALTIME ($LINENO) ' bash -x $@

cat bprof.step3 | while read ln tm trail ; do
    cumtm=`echo "$cumtm + $tm" | bc -l`
    echo $ln $tm $cumtm
    if [ "$ln" != "$prev" ] ; then
       txt=`head -$prev $script | tail -1`
        echo "$prev	$cumtm	$txt"
	cumtm=0
    fi
    prev=$ln
done \
> bprof.step4
