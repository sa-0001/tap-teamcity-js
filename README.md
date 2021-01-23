# @sa0001/tap-teamcity

[NPM][https://www.npmjs.com/package/@sa0001/tap-teamcity]

This module converts the TAP-format output of running `tap`, to the Junit-format expected by Teamcity.

## Install

```bash
npm install @sa0001/tap-teamcity
```

## Usage

It can be run from the command line, in which case it reads from stdin and writes to stdout:

```bash
./node_modules/.bin/tap ./test.js > ./test-results.tap
cat ./test-results.tap | node ./node_modules/tap-teamcity/dist/index.js > ./test-results.xml
```

Or it can be used as a module, in which case there are a few more options available:

```javascript
const tapTeamcity = require('@sa0001/tap-teamcity')

await tapTeamcity('./test-results.tap', './test-results.xml', {
	// custom top-level suite name
	suiteName: 'TAP',
	// edit the full name of the test, for example to shorten or remove the file path
	editTestName: (name) => { return name },
	// filter the lines of the error stack, to remove noise
	filterErrorStack: (line) => { return true },
})
```

## License

[MIT](http://vjpr.mit-license.org)
