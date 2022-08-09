#!/usr/bin/env bash

set -e

REGISTRY_ARG=""

if [ -n "${SCANNER_REGISTRY}" ]; then
  REGISTRY_ARG="-e SCANNER_REGISTRY=${SCANNER_REGISTRY}"
fi
if [ -n "${SCANNER_REGISTRY_USERNAME}" ]; then
  REGISTRY_ARG="${REGISTRY_ARG} -e SCANNER_REGISTRY_USERNAME=${SCANNER_REGISTRY_USERNAME}"
fi
if [ -n "${SCANNER_REGISTRY_PASSWORD}" ]; then
  REGISTRY_ARG="${REGISTRY_ARG} -e SCANNER_REGISTRY_PASSWORD=${SCANNER_REGISTRY_PASSWORD}"
fi

NV_SCANNER_IMAGE=${NV_SCANNER_IMAGE:-"neuvector/scanner:latest"}
HIGH_VUL_TO_FAIL=${HIGH_VUL_TO_FAIL:-"0"}
MEDIUM_VUL_TO_FAIL=${MEDIUM_VUL_TO_FAIL:-"0"}
OUTPUT=${OUTPUT:-"text"}
DEBUG=${DEBUG:-"false"}

docker run --name neuvector.scanner ${REGISTRY_ARG} -e SCANNER_REPOSITORY=${SCANNER_REPOSITORY} -e SCANNER_TAG=${SCANNER_TAG} -e SCANNER_ON_DEMAND=true -v /var/run/docker.sock:/var/run/docker.sock ${NV_SCANNER_IMAGE} > scanner_output.log
result=$?

if [ ${result} -ne 0 ]; then
  cat scanner_output.log
  exit ${result}
fi

if [[ ${DEBUG} == "true" ]]; then
  cat scanner_output.log;
fi

docker cp neuvector.scanner:/var/neuvector/scan_result.json scan_result.json
docker rm neuvector.scanner

echo "NeuVector scan result for ${SCANNER_REGISTRY}${SCANNER_IMAGE}:${SCANNER_TAG}" > report.log

VUL_NUM=$(cat scan_result.json | jq '.report.vulnerabilities | length')
if [ ${VUL_NUM} -eq 0 ]; then
  echo "No vulnerabilities found." >> report.log
else
  echo "Total number of vulnerabilities, $VUL_NUM, grouped by package name with vulnerability name." >> report.log
fi

FOUND_HIGH=$(cat scan_result.json | jq '.report.vulnerabilities[] | select(.severity == "High") | .severity' | wc -l)
FOUND_MEDIUM=$(cat scan_result.json | jq '.report.vulnerabilities[] | select(.severity == "Medium") | .severity' | wc -l)
VUL_LIST=$(printf '["%s"]' "${VUL_NAMES_TO_FAIL//,/\",\"}")
VUL_LIST_FOUND=$(cat scan_result.json | jq --arg arr "$VUL_LIST" '.report.vulnerabilities[] | select(.name as $n | $arr | index($n)) |.name')

if [ -z "$VUL_LIST_FOUND" ]; then
  echo -e "Found High Vulnerabilities = $FOUND_HIGH \nFound Medium Vulnerabilities = $FOUND_MEDIUM \n" >> report.log
else
  echo -e "Found specific named vulnerabilities: \n$VUL_LIST_FOUND \n\nHigh Vulnerabilities threshold = ${HIGH_VUL_TO_FAIL} \nFound High Vulnerabilities = $FOUND_HIGH \n\nMedium vulnerabilities threshold = ${MEDIUM_VUL_TO_FAIL}\nFound Medium Vulnerabilities = $FOUND_MEDIUM \n" >> report.log
fi

if [[ -n $VUL_LIST_FOUND ]]; then
  echo Fail due to found specific named vulnerabilities. >> report.log
  scan_fail="true"
elif [ ${HIGH_VUL_TO_FAIL} -ne 0 -a $FOUND_HIGH -ge ${HIGH_VUL_TO_FAIL} ]; then
  echo Fail due to high vulnerabilities found exceeds the criteria. >> report.log
  scan_fail="true"
elif [ ${MEDIUM_VUL_TO_FAIL} -ne 0 -a $FOUND_MEDIUM -ge ${MEDIUM_VUL_TO_FAIL} ]; then
  echo Fail due to medium vulnerabilities found exceeds the criteria. >> report.log
  scan_fail="true"
else
  echo Pass the criteria check. >> report.log
  scan_fail="false"
fi

if [[ $scan_fail == "true" ]]; then
  echo -e "Image scanning failed.\n\n" >> report.log
else
  echo -e "Image scanning succeed.\n\n" >> report.log
fi

if [[ "$OUTPUT" == "text" ]]; then
  cat report.log

  jq -r '[.report.vulnerabilities | group_by(.package_name) | .[] | {package_name: .[0].package_name, vuls: [ {name: .[].name, description: .[].description} ]}] | .[] | (.package_name) + ":\n" + (.vuls | [.[].name + ": " + .[].description] | join("\n")) + "\n\n"' scan_result.json
fi

if [[ "$OUTPUT" == "json" ]]; then
  cat scan_result.json
fi

if [[ "$OUTPUT" == "csv" ]]; then
  labels='"name","score","severity","description","package_name","package_version","fixed_version","link","published_timestamp","last_modified_timestamp"'
  vars=".name,.score,.severity,.description,.package_name,.package_version,.fixed_version,.link,.published_timestamp,.last_modified_timestamp"
  query='"report".vulnerabilities[]'

  cat scan_result.json | jq -r '['$labels'],(.'$query' | ['$vars'])|@csv'
fi

if [[ "$scan_fail" == "true" ]]; then
  exit 1;
fi