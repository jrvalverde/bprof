#!/bin/bash

msg='Hello world!'

for i in {0..3}
do
    echo $i
    time=$((i + 1))
    sleep $time
done
echo $msg
sleep 1
echo done

exit
#
# end
