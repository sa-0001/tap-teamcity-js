#!/usr/bin/env coffee

_ = require 'lodash'
exec = require('child_process').exec
fs = require 'fs'
tap = require 'tap'

tapTeamcity = require './index'

##======================================================================================================================

tap.test 'tap-teamcity', (t) ->
	
	input_path  = __dirname+'/../src/testdata/input.tap'
	
	expect_output_path = __dirname+'/../src/testdata/output.xml'
	actual_output_path = __dirname+'/../src/testdata/output-actual.xml'
	
	tapTeamcity input_path, actual_output_path,
		suiteName: 'TAP-Tests'
		editTestName: (name) ->
			return name.replace './repos/', ''
		filterErrorStack: (line) ->
			return false if _.includes line, 'repos/wrap-tap/src/index'
			return true
	.then ->
		
		expect_text = fs.readFileSync expect_output_path, 'utf8'
		actual_text = fs.readFileSync actual_output_path, 'utf8'
		
		t.equal actual_text, expect_text
		t.end()
