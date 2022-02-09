#!/usr/bin/env bats

. $(dirname ${BASH_SOURCE[0]})/systemd.bash
. $(dirname ${BASH_SOURCE[0]})/run.bash

function sysbox_mgr_started() {
	tail -f /var/log/sysbox-mgr.log | grep -q Ready
}

function sysbox_fs_started() {
	tail -f /var/log/sysbox-fs.log | grep -q Ready
}

function sysbox_mgr_stopped() {
	run pgrep sysbox-mgr
	if [ "$status" -eq 0 ]; then
		return 1
	else
		return 0
	fi
}

function sysbox_fs_stopped() {
	run pgrep sysbox-fs
	if [ "$status" -eq 0 ]; then
		return 1
	else
		return 0
	fi
}


function sysbox_start() {
	local flags=$@

	# NOTE: for sysbox, just being in a systemd environment is not sufficient to
	# know if we are using the sysbox systemd services (i.e, we could have installed
	# sysbox from source). Thus we check for SB_INSTALLER instead of systemd_env.

	if [ -n "$SB_INSTALLER" ]; then
		systemctl start sysbox
	else
		if [ -n "$DEBUG_ON" ]; then
			bats_bg sysbox -t -d $flags
		else
			bats_bg sysbox -t $flags
		fi
	fi

  retry_run 10 1 sysbox_fs_started
  retry_run 10 1 sysbox_mgr_started

  sleep 2
}

function sysbox_stop() {
	if [ -n "$SB_INSTALLER" ]; then
		systemctl stop sysbox
	else
		kill $(pidof sysbox-fs) && kill $(pidof sysbox-mgr)
	fi

  retry_run 10 1 sysbox_fs_stopped
  retry_run 10 1 sysbox_mgr_stopped
}

function sysbox_stopped() {
   run pgrep "sysbox-fs|sysbox-mgr"
	if [ "$status" -eq 0 ]; then
		return 1
	else
		return 0
	fi
}

# Wrapper for "sysbox-runc" command using bats
function sv_runc() {
  run __sv_runc "$@"

  # Some debug information to make life easier. bats will only print it if the
  # test failed, in which case the output is useful.
  echo "sysbox-runc $@ (status=$status):" >&2
  echo "$output" >&2
}
