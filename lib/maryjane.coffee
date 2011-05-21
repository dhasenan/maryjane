# MaryJane: a mock object library supporting Arrange Act Assert syntax.

# Standard mock methods
# Create a new mock based on:
#   - a prototype of an existing object
#   - an existing object
#   - a constructor
exports.mock = (type) ->
	if !type?
		throw new Error 'You must provide a type'
	if typeof type == 'function'
		new Mock type.prototype
	else
		new Mock type

exports.when = (mock) ->
	onMock mock, (m) -> m._mockInternals.newExpectation()

exports.verify = (mock, times) ->
	if !times?
		times = new Range(1, Infinity)
	onMock mock, (m) -> m._mockInternals.verify(times)

class Range
	constructor: (@min, @max) ->
		if !@max?
			@max = @min

	toString: ->
		if @min == @max
			return 'exactly ' + @min + ' times'
		if @min <= 0
			if @max == Infinity
				return 'any number of times'
			else
				return 'at most ' + @max + ' times'
		else
			if @max == Infinity
				return 'at least ' + @min + ' times'
			else
				return 'between ' + @min + ' and ' + @max + ' times'

	match: (point) -> point <= @max and point >= @min


# Repeat functions
exports.times = (min, max) -> new Range(min, max)
exports.never = new Range(0, 0)
exports.once = new Range(1, 1)
exports.twice = new Range(2, 2)
exports.thrice = new Range(3, 3)
exports.atLeast = (min) -> new Range(min, Infinity)
exports.atMost = (max) -> new Range(0, max)
exports.range = (min, max) -> new Range(min, max)

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

class MockInternals
	constructor: (@type, @mock) ->
		if @type == null or @type == undefined
			throw new Error 'You must provide a type'
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

		m = @findCall @unexpectedMethodCalls, field, args
		if !m?
			m = new MockOptions(@mock, field, args)
			@unexpectedMethodCalls.push m
		m.alreadyRan()
		null

	check: (field, args) ->
		@checking = false
		m = @findCall @expectedMethodCalls, field, args
		if m?
			if ! (m instanceof MockOptions)
				throw new Error 'malformed recorded expectation'
			if !@range.match m.count()
				@failCheck field, args, m
		else
			m = @findCall @unexpectedMethodCalls, field, args
			count = if !m? then 0 else m.count()
			if !@range.match count
				@failCheck field, args, m
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

	failCheck: (field, args, match) ->
		count = if match? then match.count() else 0
		argString = '('
		first = true
		for arg in args
			if first
				first = false
			else
				argString += ', '
			argString += arg
		argString += ')'

		throw new Error 'Expected ' + @typeName + '.' + field + argString + ' to be called ' + @range.toString() + ', but it was called ' + count + ' times'

	newExpectation: ->
		@recording = true
		@mock

	verify: (times) ->
		@checking = true
		@range = times
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
			return t
	else if type.hasOwnProperty field
		mock[field] = type[field]

class MockOperation
	constructor: (@retval, @exception, @cb) ->

	execute: (mock, args) ->
		if @cb?
			return @cb.apply mock, args
		else if @exception?
			throw @exception
		else
			return @retval

expectation_count = 0
class MockOptions
	constructor: (@_mock, @_name, @_args) ->
		# Use constructor assignment; otherwise the prototype fields
		# leak and you end up setting all mocks ever to strict rather
		# than just this one
		@_strict = true
		@_ops = []
		@_count = 0
		@_id = expectation_count++

	lax: ->
		@_strict = false
		return @

	thenThrow: (ex) ->
		@_ops.push new MockOperation(null, ex)
		return @

	thenReturn: (value) ->
		@_ops.push new MockOperation(value)
		return @

	thenDo: (fn) ->
		@_ops.push new MockOperation(null, null, fn)
		return @

	execute: (args) ->
		op = null
		if @_ops.length == 0
			@_count++
			return null

		if @_count > @_ops.length
			op = @_ops[@_ops.length - 1]
		else
			op = @_ops[@_count]
		@_count++
		op.execute @_mock, args

	matches: (name, args) ->
		if (@_args != null)
			if (@_strict and @_args.length != args.length)
				return false
			if @_args.length > args.length
				return false
			for i in [0 ... @_args.length]
				unless args[i] == @_args[i]
					return false
		return true

	alreadyRan: ->
		@_count++

	count: ->
		@_count
