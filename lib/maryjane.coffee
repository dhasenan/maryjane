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

# There's a rather interesting situation here worth mentioning.
# The user might have set up some calls before this:
# 	when(mock).blah().thenDo blah
# 	verifyZeroInteractions(mock)
#
# This is perfectly sensible. They might have some outrageously
# horrible or stupid test, maybe with a random element, and
# the interactions should be all-or-nothing.
#
# It's a pretty stupid use case, but we support it!
exports.verifyZeroInteractions = (mocks...) ->
	for mock in mocks
		onMock mock, (m) -> m._mockInternals.verifyZeroInteractions()

exports.verifyNoMoreInteractions = (mocks...) ->
	for mock in mocks
		onMock mock, (m) -> m._mockInternals.verifyNoMoreInteractions()

# Repeat functions
exports.times = (min, max) -> new Range(min, max)
exports.never = new Range(0, 0)
exports.once = new Range(1, 1)
exports.twice = new Range(2, 2)
exports.thrice = new Range(3, 3)
exports.atLeast = (min) -> new Range(min, Infinity)
exports.atMost = (max) -> new Range(0, max)
exports.range = (min, max) -> new Range(min, max)

class Matcher
	constructor: (@matcher) ->

exports.match = (fn) -> new Matcher fn

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

formatMethodCall = (typeName, method, args) ->
	argString = '('
	first = true
	for arg in args
		if first
			first = false
		else
			argString += ', '
		argString += arg
	argString += ')'
	return typeName + '.' + method + argString

class MockInternals
	constructor: (@type, @mock) ->
		if @type == null or @type == undefined
			throw new Error 'You must provide a type'
		for key, value of @type
			addFieldOrMethod(@mock, @type, key)

		@preparedMethodCalls = []
		@unpreparedMethodCalls = []
		@recording = false
		@checking = false
		@typeName = getName(@type)

	checkExpectedCall: (field, args) ->
		if @recording
			return @record field, args

		if @checking
			return @check field, args

		m = @findCall @preparedMethodCalls, field, args
		if m?
			return m.execute args

		m = @findCall @unpreparedMethodCalls, field, args
		if !m?
			m = new MockOptions(@mock, field, args)
			@unpreparedMethodCalls.push m
		m.alreadyRan()
		null

	check: (field, args) ->
		@checking = false
		m = @findCall @preparedMethodCalls, field, args
		if m?
			if ! (m instanceof MockOptions)
				throw new Error 'malformed recorded expectation'
			if !@range.match m.count()
				@failCheck field, args, m
			m.checkedRange @range
		else
			m = @findCall @unpreparedMethodCalls, field, args
			count = if !m? then 0 else m.count()
			if !@range.match count
				@failCheck field, args, m
			if m?
				m.checkedRange @range
		null

	record: (field, args) ->
		@recording = false
		m = new MockOptions(@mock, field, args)
		@preparedMethodCalls.push m
		m

	findCall: (list, field, args) ->
		for call in list
			if call.matches field, args
				return call
		return null

	failCheck: (field, args, match) ->
		count = if match? then match.count() else 0
		method = formatMethodCall @typeName, field, args
		throw new Error 'Expected ' + method + ' to be called ' + @range.toString() + ', but it was called ' + count + ' times'

	newExpectation: ->
		@recording = true
		@mock

	verify: (times) ->
		@checking = true
		@range = times
		@mock
	
	verifyNoMoreInteractions: ->
		# First let's run through and see if we have any excessive calls
		excessive = []
		for call in @unpreparedMethodCalls
			if call.verified() and call.inExpectedRange()
				continue
			excessive.push call
		for call in @preparedMethodCalls
			if call.verified() and call.inExpectedRange()
				continue
			excessive.push call

		if excessive.length == 0
			return

		expected = 'Expected:'
		actual = 'Actual:'
		for call in excessive
			expected += '\n\t'
			expected += call.expectationDescription()
			actual += '\n\t'
			actual += call.callDescription()

		throw new Error expected + '\n' + actual


	verifyZeroInteractions: ->
		if @unpreparedMethodCalls.length == 0 && @preparedMethodCalls.length == 0
			return
		first = true
		result = 'Expected no interactions with ' + @typeName + ', but '
		found = false
		for a in @unpreparedMethodCalls
			found = true
			if !first
				result += '\n\t'
			result += a.callDescription()
			first = false
		for a in @preparedMethodCalls
			if a.count() > 0
				found = true
				if !first
					result += '\n\t'
				result += a.callDescription()
				first = false
		if found
			throw new Error result

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
		@_matchers = []

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
				if args[i] instanceof Matcher
					if !args[i].matcher(@_args[i])
						return false
				else if @_args[i] instanceof Matcher
					if !@_args[i].matcher(args[i])
						return false
				else if args[i] != @_args[i]
					return false
		return true

	where: (matchers...) ->
		if typeof matchers[0] == 'number' or matchers[0] instanceof Number
			if matchers.length != 2
				throw new Error 'When supplying matchers by index, you must give exactly two arguments, the first of which should be a numeric index, the second of which should be a function'
			if @_matchers[matchers[0]]?
				throw new Error 'Matcher for argument ' + matchers[0] + ' specified more than once'
			@_matchers[matchers[0]] = matchers[1]
		else
			for m, i in matchers
				if typeof m != 'function'
					throw new Error 'MockOptions.where: parameter ' + i + ' is of type ' + (typeof m) + ', but it should be a function'
				@_matchers.push m
		@

	alreadyRan: ->
		@_count++

	count: ->
		@_count

	verified: ->
		@_verified

	checkedRange: (range) ->
		@_checkedRange = range

	inExpectedRange: ->
		@_checkedRange.match @_count

	expectationDescription: ->
		if @_checkedRange?
			return @method() + ' should be called ' + @_checkedRange.toString()
		else
			return @method() + ' should not be called'

	method: -> formatMethodCall(@_mock._mockInternals.typeName, @_name, @_args)

	callDescription: -> @method() + ' was called ' + @_count + ' times'
