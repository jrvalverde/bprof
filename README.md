# bprof
A simple Bash profiler written in Bash

This is a simple script that I wrote to have a bash profiler.

This profiler is written in Bash itself and somewhat trivial: it uses the execution time stamp 
of each command to build a profile of the script. As such, it will collect the time taken to 
execute each line. If a line runs a long command, it will count the time taken to run that 
command.

The profiler takes as arguments the script to be run and the arguments to that script.

Output is a file named after the name of the script run, without the extension (i.e. anything
after the last dot) and followed by 'bprof'. E.g. if we call it to profile 'test.sh' the 
output file will be called 'test.bprof' and if we call it to profile 'my.script' the output
will be 'my.bprof'. Future versions may add additional options to specify extras, but do not
rely on that, my time is limited.

The '*.bprof' file is a tab-separated file containing the line number, count of times each
line has been executed and cumulative time spent in that time, for each executed line, sorted
in line order.

If 'feedgnuplot' is installed, then an ASCII plot of line execution counts and times will also
be produced on the terminal screen, followed by a prompt asking if you want a graphical plot
saved, which will be saved as a PNG file with the name similar to the output file but ending 
in 'png' (i.e. anything after the last dot is substituted by 'png': if the profiled script is 
'test.sh' the plot will be 'test.png', if it was 'my.script', then 'my.png' will be produced).

To run this script, download file 'bash_profile.bash' or 'bprof.bash' (at your own choice, both 
are the same), make it executable (_chmod 755 bash_profile.bash_) and run it specifying the
name of the bash script to profile and any arguments required by that script, e.g.

_./bprof.bash test.sh_

to profile 'test.bash' without arguments, or

_./bprof.bash bprof.bash test.sh_

to profile 'bprof.bash' itself giving as argument 'test.sh' (i.e. while profiling 'test.sh')

This later example is worth for noting some special aspects/limitations: 'bprof.bash' will
fork (i.e. run a separate subprocess) to run 'test.sh'. Profiling will proceed along the 
main process (the profiler) but not along the subprocess, i.e. you will not get direct timing
information about how long execution in the subprocess took. 

The profiled script is run in a separate subprocess so we can redirect logging output to a 
sink of our own choice. To hopefully reduce potentially huge (we do bioinformatics, sometimes
with data worth billions of records) disk usage this is directed to a pipe, which will collect 
and process all information writing only the final summary. This means that the command 
reading for the pipe will have to wait until the separate subprocess finishes, resulting
in an artificially inflated time consumption. In other words, when interpreting the
profiling data, you must be very careful and make sure you understand correctly what the
profiled script is doing. Otherwise, surprising contradictions might occur.

in short, *you should always make sure that you know what you are doing*.

And that is all there is to it for now.
