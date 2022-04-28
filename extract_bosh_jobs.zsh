#!/usr/bin/env zsh

# Use this to extract all the jobs from an unzipped .pivotal file
# It can be used, for example, to do a census of how monit is used.

set -ex

for file in *.tgz; do
	release=${file%.tgz}
	echo $release
	if [ ! -d untarred/$release ]; then
		mkdir untarred/$release
		pushd untarred/$release
		tar xzvf ../../$file
		pushd jobs
		for job in *.tgz; do
			job_name=${job%.tgz}
			mkdir $job_name
			pushd $job_name
			tar xzvf ../$job
			popd
			rm $job
		done
		popd
		popd
	fi
done
