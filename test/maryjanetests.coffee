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
	mj.when(mock).frob(1, 8).thenDo (a, b) ->
		assert.eql a, 1
		assert.eql b, 8
		count++
	mock.frob 1, 8
	assert.eql count, 1

exports['verify call'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob 1, 8
	mj.verify(mock).frob 1, 8

exports['verify call that was not called'] = ->
	mock = mj.mock(new UnderTest())
	cb = -> mj.verify(mock).frob 1, 8
	assert.throws cb, (ex) -> ex.message == 'Expected UnderTest.frob(1, 8) to be called at least 1 times, but it was called 0 times'

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

exports['chained expectations'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1, 7).thenReturn(8).thenReturn(18).thenReturn('no thanks')
	assert.eql mock.frob(1, 7), 8
	assert.eql mock.frob(1, 7), 18
	assert.eql mock.frob(1, 7), 'no thanks'

exports['number of times called'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mj.verify(mock, mj.times(3)).frob(1, 7)

exports['number of times called: never'] = ->
	mock = mj.mock(new UnderTest())
	mj.verify(mock, mj.never).frob(1, 7)

exports['number of times called: once'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mj.verify(mock, mj.once).frob(1, 7)

exports['number of times called: twice'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mj.verify(mock, mj.twice).frob(1, 7)

exports['number of times called: thrice'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mj.verify(mock, mj.thrice).frob(1, 7)

exports['number of times called, failure, too few'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.times(3, 3)).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 3 times, but it was called 2 times'

exports['number of times called, failure, too many'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.times(3)).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 3 times, but it was called 4 times'

exports['number of times called: once, failure - too few'] = ->
	mock = mj.mock(new UnderTest())
	cb = -> mj.verify(mock, mj.once).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 1 times, but it was called 0 times'

exports['number of times called: twice, failure - too few'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.twice).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 2 times, but it was called 1 times'

exports['number of times called: thrice, failure - too few'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.thrice).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 3 times, but it was called 2 times'

exports['number of times called: never, but actually was called'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.never).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 0 times, but it was called 1 times'

exports['number of times called: once, failure - too many'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.once).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 1 times, but it was called 2 times'

exports['number of times called: twice, failure - too many'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.twice).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 2 times, but it was called 3 times'

exports['number of times called: thrice, failure - too many'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.thrice).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 3 times, but it was called 4 times'

exports['number of times called, at most'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mj.verify(mock, mj.atMost(6)).frob(1, 7)

exports['number of times called, at most, failure'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.atMost(3)).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called at most 3 times, but it was called 4 times'

exports['number of times called, at least'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mj.verify(mock, mj.atLeast(3)).frob(1, 7)

exports['number of times called, at least, failure'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.atLeast(6)).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called at least 6 times, but it was called 4 times'

exports['number of times called, range'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mj.verify(mock, mj.range(3, 5)).frob(1, 7)

exports['number of times called, range, too high'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.range(6, 19)).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called between 6 and 19 times, but it was called 4 times'

exports['number of times called, range, too low'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.range(1, 3)).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called between 1 and 3 times, but it was called 4 times'

exports['verifyNoMoreInteractions'] = ->
	mock = mj.mock(new UnderTest())
	mj.verifyNoMoreInteractions(mock)

exports['verifyNoMoreInteractions failure'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verifyNoMoreInteractions(mock)
	assert.throws cb, (ex) ->
		ex.message == 'Expected:\n\tUnderTest.frob(1, 7) should not be called\nActual:\n\tUnderTest.frob(1, 7) was called 4 times'

exports['verifyZeroInteractions'] = ->
	mock = mj.mock(new UnderTest())
	mj.verifyZeroInteractions(mock)

exports['verifyZeroInteractions with setup'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1, 7).thenReturn 4
	mj.verifyZeroInteractions(mock)

exports['verifyZeroInteractions failure'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verifyZeroInteractions(mock)
	assert.throws cb, (ex) ->
		ex.message == 'Expected no interactions with UnderTest, but UnderTest.frob(1, 7) was called 4 times'
