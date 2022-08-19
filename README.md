# @esm2cjs/node-fetch

This is a fork of https://github.com/node-fetch/node-fetch, but automatically patched to support ESM **and** CommonJS, unlike the original repository.

## Install

You can use an npm alias to install this package under the original name:

```
npm i node-fetch@npm:@esm2cjs/node-fetch
```

```jsonc
// package.json
"dependencies": {
    "node-fetch": "npm:@esm2cjs/node-fetch"
}
```

but `npm` might dedupe this incorrectly when other packages depend on the replaced package. If you can, prefer using the scoped package directly:

```
npm i @esm2cjs/node-fetch
```

```jsonc
// package.json
"dependencies": {
    "@esm2cjs/node-fetch": "^ver.si.on"
}
```

## Usage

```js
// Using ESM import syntax
import fetch from "@esm2cjs/node-fetch";

// Using CommonJS require()
const fetch = require("@esm2cjs/node-fetch").default;
```

> **Note:**
> Because the original module uses `export default`, you need to append `.default` to the `require()` call.

For more details, please see the original [repository](https://github.com/node-fetch/node-fetch).

## Sponsoring

To support my efforts in maintaining the ESM/CommonJS hybrid, please sponsor [here](https://github.com/sponsors/AlCalzone).

To support the original author of the module, please sponsor [here](https://github.com/node-fetch/node-fetch).
