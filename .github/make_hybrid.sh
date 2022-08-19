#!/bin/bash
shopt -s nullglob
set -e

echo '{ "type": "module" }' > src/package.json
echo '{ "type": "module" }' > test/package.json

rm -rf esm
mv src esm
mv @types/*.* esm/

# Replace module imports in all ts files
readarray -d '' files < <(find {esm,test} \( -name "*.js" -o -name "*.d.ts" \) -print0)
function replace_imports () {
	from=$1
	to="${2:-@esm2cjs/$from}"
	for file in "${files[@]}" ; do
		sed -i "s#'$from'#'$to'#g" "$file"
	done
}
# replace_imports "@sindresorhus/is" "@esm2cjs/is"
# replace_imports "@szmarczak/http-timer" "@esm2cjs/http-timer"
replace_imports "data-uri-to-buffer"
replace_imports "fetch-blob"
replace_imports "formdata-polyfill"
replace_imports "formdata-polyfill/esm.min.js" "@esm2cjs/formdata-polyfill"
replace_imports "fetch-blob/from.js" "@esm2cjs/fetch-blob/from.js"

# Fix relative imports
for file in "${files[@]}" ; do
	sed -i "s#/src/#/esm/#g" "$file"
done

PJSON=$(cat package.json | jq --tab '
	del(.type)
	| .description = .description + ". This is a fork of node-fetch/node-fetch, but with CommonJS support."
	| .repository = "esm2cjs/" + .name
	| .name |= "@esm2cjs/" + .
	| .author = { "name": "Dominic Griesel", "email": "d.griesel@gmx.net" }
	| .publishConfig = { "access": "public" }
	| .funding = "https://github.com/sponsors/AlCalzone"
	| .main = "cjs/index.js"
	| .module = "esm/index.js"
	| .files = [""]
	| .exports = {}
	| .exports["."].import = "./esm/index.js"
	| .exports["."].require = "./cjs/index.js"
	| .exports["./package.json"] = "./package.json"
	| .types = "esm/index.d.ts"
	| .typesVersions = {}
	| .typesVersions["*"] = {}
	| .typesVersions["*"]["esm/index.d.ts"] = ["esm/index.d.ts"]
	| .typesVersions["*"]["cjs/index.d.ts"] = ["esm/index.d.ts"]
	| .typesVersions["*"]["*"] = ["esm/*"]
	| .scripts["to-cjs"] = "esm2cjs --in esm --out cjs -t node12"

	| .dependencies["@esm2cjs/data-uri-to-buffer"] = .dependencies["data-uri-to-buffer"]
	| del(.dependencies["data-uri-to-buffer"])
	| .dependencies["@esm2cjs/fetch-blob"] = .dependencies["fetch-blob"]
	| del(.dependencies["fetch-blob"])
	| .dependencies["@esm2cjs/formdata-polyfill"] = .dependencies["formdata-polyfill"]
	| del(.dependencies["formdata-polyfill"])

	| .xo.ignores |= . + ["cjs/", "test/", "**/*.d.ts"]
')
echo "$PJSON" > package.json

# Update package.json -> version if upstream forgot to update it
if [[ ! -z "${TAG}" ]] ; then
	VERSION=$(echo "${TAG/v/}")
	PJSON=$(cat package.json | jq --tab --arg VERSION "$VERSION" '.version = $VERSION')
	echo "$PJSON" > package.json
fi

npm i -D @alcalzone/esm2cjs
npm run to-cjs
npm uninstall -D @alcalzone/esm2cjs

PJSON=$(cat package.json | jq --tab 'del(.scripts["to-cjs"])')
echo "$PJSON" > package.json

# Some modules are written in a way that ESBuild double-wraps the default export
readarray -d '' files_new < <(find cjs \( -name "*.js" -o -name "*.d.ts" \) -print0)
for file in "${files_new[@]}" ; do
	sed -i -E 's#__toESM\((require\("\./.+"\)), 1\);#\1;#g' "$file"
done


npm test
