mj = require 'maryjane'
assert = require 'assert'

class UnderTest
	frob: (a, b) ->
		throw 'DIVIDE BY CUCUMBER ERROR'

	fizz: (a) ->
		a + 17

class HasFields
	constructor: ->
		@foo = 17
		@bar = 'drinky winky!'

exports['regurgitate an expected answer'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1, 7).thenReturn 15
	assert.eql mock.frob(1, 7), 15

exports['leave the original type alone'] = ->
	a = mj.mock(new UnderTest())
	mj.when(a).frob(1, 7).thenReturn 15
	b = new UnderTest()
	assert.throws((-> b.frob(1, 7)), 'DIVIDE BY CUCUMBER ERROR')

exports['return null by default'] = ->
	b = mj.mock(new UnderTest())
	assert.eql b._mockInternals.expectedMethodCalls.length, 0
	assert.isNull b.frob(1, 7)

exports['wrong arguments ignored'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1, 7).thenReturn 15
	assert.isNull mock.frob(1, 8)

exports['not strict and i didn\'t specify one argument'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1).lax().thenReturn 15
	assert.eql mock.frob(1, 8), 15

exports['strict and i didn\'t specify one argument'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1).thenReturn 15
	assert.eql mock.frob(1, 8), null

exports['throw an exception'] = ->
	mock = mj.mock(new UnderTest())
	ex = "who's the what now?"
	mj.when(mock).frob(1, 8).thenThrow ex
	assert.throws((-> mock.frob(1, 8)), ex)

exports['user callback'] = ->
	mock = mj.mock(new UnderTest())
	count = 0
	mj.when(mock).frob(1, 8).thenDo -> count++
	mock.frob 1, 8
	assert.eql count, 1

exports['verify call'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob 1, 8
	mj.verify(mock).frob 1, 8

exports['verify call that was not called'] = ->
	mock = mj.mock(new UnderTest())
	cb = -> mj.verify(mock).frob 1, 8
	assert.throws cb, (ex) -> ex.message == 'Expected UnderTest.frob(1, 8) to be called at least once, but it was never called'

exports['mock from base function prototype'] = ->
	mock = mj.mock(UnderTest.prototype)
	mock.frob 1, 8
	mj.verify(mock).frob 1, 8

exports['mock from base function'] = ->
	mock = mj.mock(UnderTest)
	mock.frob 1, 8
	mj.verify(mock).frob 1, 8

exports['mock copies fields'] = ->
	h = new HasFields()
	mock = mj.mock(h)
	assert.eql mock.foo, h.foo
	assert.eql mock.bar, h.bar
