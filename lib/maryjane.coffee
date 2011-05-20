# MaryJane: a mock object library supporting Arrange Act Assert syntax.

exports.mock = (type) ->
	if !type?
		throw new Error 'You must provide a type'
	if typeof type == 'function'
		new Mock type.prototype
	else
		new Mock type

onMock = (mock, cb) ->
	if !(mock instanceof Mock)
		throw new Error 'You can only use this with mock objects'
	if mock._mockInternals?
		return cb mock
	else
		throw new Error 'Malformed mock object'

getName = (type) ->
	f = type.constructor.toString()
	f = f.split(' ', 2)[1]
	f = f.split('(', 2)[0]
	f.replace ' ', ''


exports.when = (mock) ->
	onMock mock, (m) -> m._mockInternals.newExpectation()

exports.verify = (mock) ->
	onMock mock, (m) -> m._mockInternals.verify()


class MockInternals
	constructor: (@type, @mock) ->
		if @type == null or @type == undefined
			throw new Error 'You must provide a type'
		#console.log 'working on type %s', @type.constructor.toString()
		for key, value of @type
			addFieldOrMethod(@mock, @type, key)

		@expectedMethodCalls = []
		@unexpectedMethodCalls = []
		@recording = false
		@checking = false
		@typeName = getName(@type)

	checkExpectedCall: (field, args) ->
		if @recording
			return @record field, args

		if @checking
			return @check field, args

		m = @findCall @expectedMethodCalls, field, args
		if m?
			return m.execute args

		m = new MockOptions(@mock, field, args)
		@unexpectedMethodCalls.push m
		null

	check: (field, args) ->
		@checking = false
		m = @findCall @expectedMethodCalls, field, args
		if m?
			if m.count == 0
				@failCheck field, args
		else
			m = @findCall @unexpectedMethodCalls, field, args
			if !m?
				@failCheck field, args
		null

	record: (field, args) ->
		@recording = false
		m = new MockOptions(@mock, field, args)
		@expectedMethodCalls.push m
		m

	findCall: (list, field, args) ->
		for call in list
			if call.matches field, args
				return call
		return null

	failCheck: (field, args) ->
		argString = '('
		first = true
		for arg in args
			if first
				first = false
			else
				argString += ', '
			argString += arg
		argString += ')'

		throw new Error 'Expected ' + @typeName + '.' + field + argString + ' to be called at least once, but it was never called'

	newExpectation: ->
		@recording = true
		@mock

	verify: ->
		@checking = true
		@mock

class Mock
	constructor: (type) ->
		if type == null or type == undefined
			throw new Error 'You must provide a type'
		@_mockInternals = new MockInternals(type, @)

addFieldOrMethod = (mock, type, field) ->
	f = type[field]
	if typeof f == 'function'
		mock[field] = () ->
			t = mock._mockInternals.checkExpectedCall field, arguments
			#console.log 'outer wrapper returning %s', t.toString()
			return t
	else if type.hasOwnProperty field
		mock[field] = type[field]

class MockOptions
	constructor: (@_mock, @_name, @_args) ->
		# Use constructor assignment; otherwise the prototype fields
		# leak and you end up setting all mocks ever to strict rather
		# than just this one
		@_strict = true
		@_returns = null
		@_ex = null
		@_count = 0
		@_userFunc = null

	lax: ->
		@_strict = false
		return @
	thenThrow: (ex) ->
		@_ex = ex
		return @
	thenReturn: (value) ->
		@_returns = value
		return @
	thenDo: (fn) ->
		@_userFunc = fn
		return @

	execute: (args) ->
		@_count++
		if (@_userFunc != null)
			#console.log 'calling user func'
			return @_userFunc(args)
		if (@_ex != null)
			#console.log 'throwing exception'
			throw @_ex
		if @_returns != null
			#console.log 'returning %s', @_returns.toString()
			return @_returns
		return null

	matches: (name, args) ->
		#console.log 'checking %s vs expected %s', args, @_args
		if (@_args != null)
			if (@_strict and @_args.length != args.length)
				#console.log 'strict and wrong number of parameters'
				return false
			if @_args.length > args.length
				#console.log 'too few parameters'
				return false
			for i in [0 ... @_args.length]
				unless args[i] == @_args[i]
					#console.log "argument %d didn't match; expected %s but got %s", i, @_args[i], args[i]
					return false
		#console.log 'nothing for it but to match'
		return true

