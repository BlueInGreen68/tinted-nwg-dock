#!/bin/bash

declare -g configFile="./templates/config.yaml"
declare -g fileName
declare -g headJson
declare -g bodyJson

declare -g schemeSystem
declare -g schemeSlug
declare -g schemeName
declare -g schemeAuthor
declare -g schemeVariant

readarray -t schemesFiles < <(find "$HOME"/projects/schemes/base16/ -type f -iname '*.yaml')

function createFile() {
	# Extract filename entry from config
	yq '.default.filename' "$configFile" >"/tmp/filename-base16-nwg-dock.txt"

	fileName=$(lustache-cli -i "/tmp/filename-base16-nwg-dock.txt" --json-data "$headJson")

	if [[ -e ./"$fileName" ]]; then
		return
	else
		touch ./"$fileName"
	fi
}

function getProperty() {
	yq -oy "$schemeFile" | yq -o=json -r ".$1"
}

for schemeFile in "${schemesFiles[@]}"; do
	schemeName=$(getProperty "name")
	schemeAuthor=$(getProperty "author")
	schemeSlug=$(basename "$schemeFile" .yaml)
	schemeSlugUnderscored="${schemeSlug//-/_}"
	schemeSystem=$(yq '.default.supported-systems[0]' "$configFile")
	schemeVariant=$(getProperty "variant")

	headJson=$(
		jq \
			--null-input \
			--arg schemeName "$schemeName" \
			--arg schemeAuthor "$schemeAuthor" \
			--arg schemeSlug "$schemeSlug" \
			--arg schemeSlugUnderscored "$schemeSlugUnderscored" \
			--arg schemeSystem "$schemeSystem" \
			--arg schemeVariant "$schemeVariant" \
			'{ "scheme-name": $schemeName, "scheme-author": $schemeAuthor, "scheme-slug": $schemeSlug, "scheme-slug-underscored": $schemeSlugUnderscored, "scheme-system": $schemeSystem, "scheme-variant": $schemeVariant, hasVariant: (if $schemeVariant != "" then "true" else "false" end) }'
	)

	bodyJson=$(getProperty "palette")

	createFile

	lustache-cli -i ./templates/head.mustache --json-data "$headJson" >./"$fileName"

	echo >>./"$fileName"

	lustache-cli -i ./templates/body.mustache --json-data "$bodyJson" >>./"$fileName"
done
