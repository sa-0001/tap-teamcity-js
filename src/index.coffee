_ = require 'lodash'
fs = require 'fs'
PassThroughStream = require('stream').PassThrough
readline = require 'readline'
TapParser = require 'tap-parser'

##======================================================================================================================

escapeXml = (str) ->
	return String(str)
		.replace /"/g, '&quot;'
		.replace /</g, '&lt;'
		.replace />/g, '&gt;'
		.replace /&/g, '&amp;'

getFullname = (test) ->
	fullname = test.name
	
	parent = test
	while parent = parent.parent
		if parent.name
			fullname = parent.name + ' ￫ ' + fullname
	
	return fullname

processTest = (opts, test) ->
	fullname = getFullname test
	
	if opts.editTestName
		fullname = opts.editTestName fullname
	
	test.fullnameEscaped = escapeXml fullname
	
	return test

convert = (in_path, out_path, opts = {}) ->
	return new Promise (resolve, reject) ->
		
		_.defaults opts,
			suiteName: 'TAP'
			editTestName: null
			filterErrorStack: null
		
		if _.isString in_path
			read_stream = fs.createReadStream in_path
		else
			read_stream = in_path
		
		if _.isString out_path
			write_stream = fs.createWriteStream out_path
		else
			write_stream = out_path
		
		##----------------------------------------------------------------------
		
		# header & footer
		
		writeHeader = ->
			write_stream.write """
				<?xml version="1.0" encoding="UTF-8"?>
				<testsuite name="#{escapeXml opts.suiteName}">\n
			"""
		
		writeFooter = ->
			write_stream.write '</testsuite>\n', ->
				resolve()
		
		##----------------------------------------------------------------------
		
		# test result
		
		writeSkip = (parent, skip) ->
			write_stream.write """
				<testcase name="#{parent.fullnameEscaped} ￫ #{skip.name}">
					<skipped message="skip"/>
				</testcase>\n
			"""
		
		writeTodo = (parent, todo) ->
			write_stream.write """
				<testcase name="#{parent.fullnameEscaped} ￫ #{todo.name}">
					<skipped message="todo"/>
				</testcase>\n
			"""
		
		writeTest = (test) ->
			processTest opts, test
			
			test.skips?.forEach (t) ->
				if t.skip then writeSkip test, t
				if t.todo then writeTodo test, t
			
			if test.results.fail
				write_stream.write """
					<testcase name="#{test.fullnameEscaped}">
						<failure message="#{test.results?.failures?[0]?.name || test.fullnameEscaped}"><![CDATA[
					#{escapeXml test.lines.join('').trim()}
						]]></failure>
					</testcase>\n
				"""
			else
				write_stream.write """
					<testcase name="#{test.fullnameEscaped}"></testcase>\n
				"""
		
		##----------------------------------------------------------------------
		
		# tap-parser
		
		rootParser = new TapParser
			buffered: true
			preserveWhitespace: false
		
		parserStack = []
		
		attachListeners = (parser) ->
			parserStack.push parser
			
			parser.on 'child', (child) ->
				
				child.on 'line', (line) ->
					child.lines ?= []
					child.lines.push line
				
				child.on 'complete', (result) ->
					child.result = result
					writeTest child
					
					parserStack.pop()
				
				attachListeners child
			
			parser.on 'extra', (extra) ->
				parserStack.forEach (p) ->
					p.lines ?= []
					p.lines.push extra
			
			parser.on 'skip', (test) ->
				_.last(parserStack).skips ?= []
				_.last(parserStack).skips.push test
			
			parser.on 'todo', (test) ->
				_.last(parserStack).skips ?= []
				_.last(parserStack).skips.push test
		
		attachListeners rootParser
		
		##----------------------------------------------------------------------
		
		# passthrough
		
		passthrough = new PassThroughStream()
		
		passthrough.pipe rootParser
		
		##----------------------------------------------------------------------
		
		# readline
		
		writeHeader()
		
		rl = readline.createInterface
			input: read_stream
		
		rl.on 'line', (line) ->
			# skip lines with only whitespace
			return if line.match /^[\s\t\n\r]*$/
			passthrough.write line+'\n', 'utf8'
		
		rl.on 'close', writeFooter

##======================================================================================================================

if require.main == module
	# run from command line
	convert(process.stdin, process.stdout).then ->
		process.exit()
else
	# required as a module
	module.exports = convert
