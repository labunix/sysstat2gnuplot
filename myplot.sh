#!/bin/bash
# ver 0.1
# labunix@linux.jp
#
# 更新履歴
# 2012/04/01
#
# デフォルトをsvgではなくpngに変更
# メモリ    %計算の*100抜けの修正
# スワップ　%計算の追加
#
# スワップ　せっかくSwapTotalを取得しているので、
#           (swapfree+swapuse)の計算と置き換え

set -e
DATA="png"

if [ `id -u` -ne "0" ];then
  echo "Not Permit User!"
  exit 2
fi

DAY=$2
if [ "x$2" == "x" ];then
  echo "Useage $0 [cpu|mem|net|disk] [DAY]"
  echo "DAY is 01 to 31" 
  exit 2
fi
case $1 in
cpu)
    # TITLE0=time
    export TITLE1=user;
    export TITLE2=system;
    export TITLE3=iowait;
    export TITLE4=idle;
    export INPUT=cpu.txt;
    export OUTPUT="cpu.${DATA}";
    LANG=C sar -u -f /var/log/sysstat/sa${DAY} | \
    sed s/" * "/","/g | \
    grep -v "RESTART\|^\$\|^Average\|^Linux\|%" | \
    awk -F\, '{print $1 "\t" $3 "\t" $5 "\t" $6 "\t" $8 }' > "${INPUT}"
    ;;
mem)
    # TITLE0=time
    export TITLE1=kbmemfree;
    export TITLE2=kbmemused;
    export TITLE3=kbbuffers;
    export TITLE4=kbcached;
    export INPUT=mem.txt;
    export OUTPUT="mem.${DATA}";
    export MEMTOTAL=`grep MemTotal /proc/meminfo | awk '{print $2}'`
    LANG=C sar -r -f /var/log/sysstat/sa${DAY} | \
    sed s/" * "/","/g | \
    grep -v "RESTART\|^\$\|^Average\|^Linux\|%" | \
    awk -F\, '{print $1 "\t" ($2/'${MEMTOTAL}')*100 "\t" ($3/'${MEMTOTAL}')*100"\t" ($5/'${MEMTOTAL}')*100 "\t" ($6/'${MEMTOTAL}')*100 }' > "$INPUT" 
    ;;
net)
    # TITLE0=time
    export TITLE1=rxpck;
    export TITLE2=txpck;
    export TITLE3=rxcmp;
    export TITLE4=txcmp;
    export INPUT=net.txt;
    export OUTPUT="net.${DATA}";
    LANG=C sar -n DEV -f /var/log/sysstat/sa${DAY} | \
    sed s/" * "/","/g | \
    grep -v "RESTART\|^\$\|^Average\|^Linux\|%" | grep eth0 | \
    awk -F\, '{print $1 "\t" $3 "\t" $4 "\t" $7 "\t" $8}' > "$INPUT"
    ;;
swap)
    # TITLE0=time
    export TITLE1='kbswpused/SwapTotal';
    export TITLE2='kbswpfree/SwapTotal';
    export TITLE3='%swpused';
    export TITLE4='%swpcad';
    export INPUT=swap.txt;
    export OUTPUT="swap.${DATA}";
    export SWAPTOTAL=`grep SwapTotal /proc/meminfo  | awk '{print $2}'`
    LANG=C sar -S -f /var/log/sysstat/sa${DAY} | \
    sed s/" * "/","/g | \
    grep -v "RESTART\|^\$\|^Average\|^Linux\|%" | \
    awk -F\, '{print $1 "\t" ($3/'${SWAPTOTAL}')*100 "\t" ($2/'${SWAPTOTAL}')*100 "\t" $4 "\t" $6}' > "$INPUT"
    ;;
disk)
    # TITLE0=time
    export TITLE1=rtps;
    export TITLE2=wtps;
    export TITLE3=bread;
    export TITLE4=bwrtn;
    export INPUT=disk.txt;
    export OUTPUT="disk.${DATA}";
    LANG=C sar -b -f /var/log/sysstat/sa${DAY} | \
    sed s/" * "/","/g | \
    grep -v "RESTART\|^\$\|^Average\|^Linux\|%" | \
    awk -F\, '{print $1 "\t" $3 "\t" $4 "\t" $5 "\t" $6}' > "$INPUT"
    ;;
*)
    echo "Useage $0 [cpu|mem|net|disk] [DAY]"
    echo "DAY is 01 to 31"
    exit 3
    ;;
esac

# for svg 1024x600
#(echo 'set terminal svg size 1024,600 fixed fname '"'"'Times'"'"' fsize 10 butt solid';
# for png 1024x600
#(echo 'set terminal png size 1024,600';
# for png 1600x1200
#(echo 'set terminal png size 1600,1200';
# for png 2560x1440
#(echo 'set terminal png size 2560,1440';
# for png 3200x1800 -> 16:9
(echo 'set terminal png size 3200,1800';
 echo 'set output "'$OUTPUT'"';
# add hostname
# echo 'set title "'$1 `hostname -s`'"';
echo 'set title "'$1 '"';
 echo 'set xdata time';
 echo 'set key outside';
 echo 'set timefmt "%H:%M:%S"';
 echo 'set format x "%H:%M"';
 echo 'set yrange [0:100]';
 echo 'plot "'$INPUT'" using 1:2 title "'${TITLE1}'" with lines, \
  "'$INPUT'" using 1:3 title "'${TITLE2}'" with lines, \
  "'$INPUT'" using 1:4 title "'${TITLE3}'" with lines, \
  "'$INPUT'" using 1:5 title "'${TITLE4}'" with lines';
) | gnuplot

