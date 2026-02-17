#!/usr/bin/dumb-init /bin/bash
# Script to download episodes from BBC iPlayer

function download() {

	shows="${1}"

	echo "[info] Show Name defined as '${shows}'"

	# split comma separated string into list from SHOW env variable
	IFS=',' read -ra showlist <<< "${shows}"

	# process each show in the list
	for show in "${showlist[@]}"; do

		# strip whitespace from start and end of show
		show=$(echo "${show}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')

		echo "[info] Processing show '${show}'..."

		echo "[info] Delete partial downloads from incomplete folder '/data/get_iplayer/incomplete/'..."
		find /data/get_iplayer/incomplete/ -type f -name "*partial*" -delete

		# if show_type is name then set pid_command to show name, else use pid (show name as pid)
		/usr/bin/get_iplayer --type=radio --profile-dir /config --atomicparsley /usr/sbin/atomicparsley --get "${show}" --output "/data/get_iplayer/incomplete/${show}" --command-radio='ffmpeg -i "<filename>" -c:v copy -c:a libmp3lame -b:a 320k -y "/data/get_iplayer/incomplete/${show}/<fileprefix>.mp3" && rm "<filename>"'
	done

}

function move() {

	# check incomplete folder DOES contain files with mp4 extension
	if [[ -n $(find /data/get_iplayer/incomplete/ -name '*.mp3') ]]; then

		echo "[info] Copying show folders in incomplete to completed..."
		cp -rf "/data/get_iplayer/incomplete"/* "/data/completed/"

		# if copy successful then delete show folder in incomplete folder
		if [[ $? -eq 0 ]]; then

			echo "[info] Copy successful, deleting incomplete folders..."
			rm -rf "/data/get_iplayer/incomplete"/*

		else

			echo "[error] Copy failed, skipping deletion of show folders in incomplete folder..."

		fi

	fi

}

function start() {

	# make folder for incomplete downloads
	mkdir -p "/data/get_iplayer/incomplete"

	# make folder for completed downloads
	mkdir -p "/data/completed"

	# set locations for ffmpeg and atomicparsley
	/usr/bin/get_iplayer --profile-dir /config --prefs-add --ffmpeg='/usr/sbin/ffmpeg' --atomicparsley='/usr/sbin/atomicparsley'

	while true; do

		if [[ -n "${SHOWS}" ]]; then
			download "${SHOWS}" "name"
		fi

		# run function to move downloaded tv shows
		move

		# if env variable SCHEDULE not defined then use default
		if [[ -z "${SCHEDULE}" ]]; then

			echo "[info] Env var SCHEDULE not defined, sleeping for 12 hours..."
			sleep 12h

		else

			echo "[info] Env var SCHEDULE defined, sleeping for ${SCHEDULE}..."
			sleep "${SCHEDULE}"

		fi

	done

}

# if 'SHOWS' env var not defined then exit
if [ -z "${SHOWS}" ]; then

	echo "[crit] Show Name is not defined, please specify show name to download using the environment variable 'SHOWS'"

fi

# run function to start processing
start
