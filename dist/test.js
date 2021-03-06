// Generated by CoffeeScript 1.12.7
var _, exec, fs, tap, tapTeamcity;

_ = require('lodash');

exec = require('child_process').exec;

fs = require('fs');

tap = require('tap');

tapTeamcity = require('./index');

tap.test('tap-teamcity', function(t) {
  var actual_output_path, expect_output_path, input_path;
  input_path = __dirname + '/../src/testdata/input.tap';
  expect_output_path = __dirname + '/../src/testdata/output.xml';
  actual_output_path = __dirname + '/../src/testdata/output-actual.xml';
  return tapTeamcity(input_path, actual_output_path, {
    suiteName: 'TAP-Tests',
    editTestName: function(name) {
      return name.replace('./repos/', '');
    },
    filterErrorStack: function(line) {
      if (_.includes(line, 'repos/wrap-tap/src/index')) {
        return false;
      }
      return true;
    }
  }).then(function() {
    var actual_text, expect_text;
    expect_text = fs.readFileSync(expect_output_path, 'utf8');
    actual_text = fs.readFileSync(actual_output_path, 'utf8');
    t.equal(actual_text, expect_text);
    return t.end();
  });
});
