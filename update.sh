#!/bin/bash

# update.sh - Scripts to merge WMO data with Wikidata.
# Copyright (C) 2021  Pierre Choffet
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of version 3 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -euxo pipefail

# Script cache dir
CACHE_DIR=${CACHE_DIR:-"${HOME}/.cache/wmo_to_wikidata/"}

# Any stations cache older than this (in minutes) will be updated
STATIONS_MAX_AGE=${STATIONS_MAX_AGE:=1440}

# Hardcoded values
OSCAR_STATIONS_URL='https://oscar.wmo.int/surface/rest/api/search/station'
STATIONS_CACHE_PATH="${CACHE_DIR}/stations.xml"
STATIONS_CLEANED_CACHE_PATH="${CACHE_DIR}/stations_cleaned.xml"

# Fail if something is missing
function assertEnvironment() {
	for name in curl yq xmlstarlet
	do
		if ! type "${name}" > /dev/null 2>&1
		then
			echo "Cannot find ${name}. Exiting"
			exit 1
		fi
	done
}

# Update stations cache, if needed
function ensureStationsCache() {
	local -r outdated_path=$(find "${STATIONS_CACHE_PATH}" -mmin "+${STATIONS_MAX_AGE}")

	if [ ! -f "${STATIONS_CACHE_PATH}" ]||[ "${outdated_path}" != ''  ]
	then
		local -r stations_download_path="$(mktemp)"
		
		mkdir -p "${CACHE_DIR}"
		curl "${OSCAR_STATIONS_URL}" > "${stations_download_path}"
		echo "<?xml version='1.0' encoding='utf-8' ?><stations>$(yq -x --xml-root station .stationSearchResults "${stations_download_path}")</stations>" | xmlstarlet fo -t > "${STATIONS_CACHE_PATH}"
		rm "${stations_download_path}"
	fi
}

assertEnvironment
ensureStationsCache

# Clean stations cache for known problems
xmlstarlet tr -s xslts/stations_clean.xslt "${STATIONS_CACHE_PATH}" | xmlstarlet fo -t > "${STATIONS_CLEANED_CACHE_PATH}"

# Validate stations cache
xmlstarlet val -e -s schemas/stations.xsd "${STATIONS_CLEANED_CACHE_PATH}"
