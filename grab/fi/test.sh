#!/bin/sh
#
# Based on the tests exsecuted on <http://www.crustynet.org.uk/~xmltv-tester>
#
# Check log file for errors
check_log() {
    local log=$1
    if [ -s "$log" ]; then
	( \
	    echo "Test with log '$log' failed:"; \
	    echo; \
	    cat $log; \
	    echo; \
	) 1>&2
    fi
}

# Configuration
set -x -e
build_dir=$(pwd)
test_dir=${build_dir}/test-fi
export PERL5LIB=${build_dir}/blib/lib

# Command line options
for arg in $*; do
    case $arg in
	reuse)
	    preserve_directory=1
	    ;;
	
	*)
	    echo 1>&2 "unknown option '$arg"
	    exit 1
	    ;;
    esac
done

# Setup
if [ -z "$preserve_directory" ]; then
    rm -rf ${test_dir}
    mkdir ${test_dir}
fi
cd ${test_dir}
set +e


#
# Tests
#
# Original test run with 2 days and using test.conf from repository
#
perl -I ${build_dir}/blib/lib ${build_dir}/grab/fi/tv_grab_fi --ahdmegkeja > /dev/null 2>&1
perl -I ${build_dir}/blib/lib ${build_dir}/grab/fi/tv_grab_fi --version > /dev/null 2>&1
perl -I ${build_dir}/blib/lib ${build_dir}/grab/fi/tv_grab_fi --description > /dev/null 2>&1
perl -I ${build_dir}/blib/lib ${build_dir}/grab/fi/tv_grab_fi --config-file ${build_dir}/grab/fi/test.conf --offset 1 --days 2 --cache  t_fi_cache  > t_fi_1_2.xml --quiet 2>t_fi_1.log
${build_dir}/blib/script/tv_cat t_fi_1_2.xml > /dev/null 2>t_fi_6.log
check_log t_fi_6.log
${build_dir}/blib/script/tv_sort --duplicate-error t_fi_1_2.xml > t_fi_1_2.sorted.xml 2>t_fi_1_2.sort.log
check_log t_fi_1_2.sort.log
perl -I ${build_dir}/blib/lib ${build_dir}/grab/fi/tv_grab_fi --config-file ${build_dir}/grab/fi/test.conf --offset 1 --days 1 --cache  t_fi_cache  --output t_fi_1_1.xml  2>t_fi_2.log
perl -I ${build_dir}/blib/lib ${build_dir}/grab/fi/tv_grab_fi --config-file ${build_dir}/grab/fi/test.conf --offset 2 --days 1 --cache  t_fi_cache  > t_fi_2_1.xml 2>t_fi_3.log
perl -I ${build_dir}/blib/lib ${build_dir}/grab/fi/tv_grab_fi --config-file ${build_dir}/grab/fi/test.conf --offset 1 --days 2 --cache  t_fi_cache  --quiet --output t_fi_4.xml 2>t_fi_4.log
${build_dir}/blib/script/tv_cat t_fi_1_1.xml t_fi_2_1.xml > t_fi_1_2-2.xml 2>t_fi_5.log
check_log t_fi_5.log
${build_dir}/blib/script/tv_sort --duplicate-error t_fi_1_2-2.xml > t_fi_1_2-2.sorted.xml 2>t_fi_7.log
check_log t_fi_7.log
diff t_fi_1_2.sorted.xml t_fi_1_2-2.sorted.xml > t_fi__1_2.diff
check_log t_fi__1_2.diff

#
# Modified test run with 9 days and modified test.conf
#
perl -pe 's/^#(channel\s+(?:4|5|6|7|8|9|10|11|12)\s+.+)/$1/' <${build_dir}/grab/fi/test.conf >${test_dir}/test.conf
perl -I ${build_dir}/blib/lib ${build_dir}/grab/fi/tv_grab_fi --config-file ${test_dir}/test.conf --offset 1 --days 9 --cache  t_fi_cache  >t_fi_full_10.xml --quiet 2>t_fi_full.log
for d in $(seq 1 9); do
    perl -I ${build_dir}/blib/lib ${build_dir}/grab/fi/tv_grab_fi --config-file ${test_dir}/test.conf --offset $d --days 1 --cache  t_fi_cache  >t_fi_single_$d.xml --quiet 2>>t_fi_single.log
done
${build_dir}/blib/script/tv_cat t_fi_full_10.xml > /dev/null 2>t_fi_output.log
${build_dir}/blib/script/tv_sort --duplicate-error t_fi_full_10.xml > t_fi_full_10.sorted.xml 2>>t_fi_output.log
${build_dir}/blib/script/tv_cat t_fi_single_*.xml >t_fi_full_10-2.xml 2>>t_fi_output.log
${build_dir}/blib/script/tv_sort --duplicate-error t_fi_full_10-2.xml > t_fi_full_10-2.sorted.xml 2>>t_fi_output.log
check_log t_fi_output.log
diff t_fi_full_10.sorted.xml t_fi_full_10-2.sorted.xml >t_fi__10.diff
check_log t_fi__10.diff
