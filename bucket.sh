while :
do
	/home/louis/bucket/bucket.pl
	echo "bucket exited with exit code $?.  Respawning.." >&2
	sleep 15
done
