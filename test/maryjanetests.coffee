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

tests = {}

tests['regurgitate an expected answer'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1, 7).thenReturn 15
	assert.equal mock.frob(1, 7), 15

tests['leave the original type alone'] = ->
	a = mj.mock(new UnderTest())
	mj.when(a).frob(1, 7).thenReturn 15
	b = new UnderTest()
	assert.throws((-> b.frob(1, 7)), 'DIVIDE BY CUCUMBER ERROR')

tests['return null by default'] = ->
	b = mj.mock(new UnderTest())
	assert.equal null, b.frob(1, 7)

tests['wrong arguments ignored'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1, 7).thenReturn 15
	assert.equal null, mock.frob(1, 8)

tests['not strict and i didn\'t specify one argument'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1).lax().thenReturn 15
	assert.equal mock.frob(1, 8), 15

tests['strict and i didn\'t specify one argument'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1).thenReturn 15
	assert.equal mock.frob(1, 8), null

tests['throw an exception'] = ->
	mock = mj.mock(new UnderTest())
	ex = "who's the what now?"
	mj.when(mock).frob(1, 8).thenThrow ex
	assert.throws((-> mock.frob(1, 8)), ex)

tests['user callback'] = ->
	mock = mj.mock(new UnderTest())
	count = 0
	mj.when(mock).frob(1, 8).thenDo (a, b) ->
		assert.equal a, 1
		assert.equal b, 8
		count++
	mock.frob 1, 8
	assert.equal count, 1

tests['verify call'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob 1, 8
	mj.verify(mock).frob 1, 8

tests['verify call that was not called'] = ->
	mock = mj.mock(new UnderTest())
	cb = -> mj.verify(mock).frob 1, 8
	assert.throws cb, (ex) -> ex.message == 'Expected UnderTest.frob(1, 8) to be called at least 1 times, but it was called 0 times'

tests['mock from base function prototype'] = ->
	mock = mj.mock(UnderTest.prototype)
	mock.frob 1, 8
	mj.verify(mock).frob 1, 8

tests['mock from base function'] = ->
	mock = mj.mock(UnderTest)
	mock.frob 1, 8
	mj.verify(mock).frob 1, 8

tests['mock copies fields'] = ->
	h = new HasFields()
	mock = mj.mock(h)
	assert.equal mock.foo, h.foo
	assert.equal mock.bar, h.bar

tests['chained expectations'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1, 7).thenReturn(8).thenReturn(18).thenReturn('no thanks')
	assert.equal mock.frob(1, 7), 8
	assert.equal mock.frob(1, 7), 18
	assert.equal mock.frob(1, 7), 'no thanks'

tests['number of times called'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mj.verify(mock, mj.times(3)).frob(1, 7)

tests['number of times called: never'] = ->
	mock = mj.mock(new UnderTest())
	mj.verify(mock, mj.never).frob(1, 7)

tests['number of times called: once'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mj.verify(mock, mj.once).frob(1, 7)

tests['number of times called: twice'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mj.verify(mock, mj.twice).frob(1, 7)

tests['number of times called: thrice'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mj.verify(mock, mj.thrice).frob(1, 7)

tests['number of times called, failure, too few'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.times(3, 3)).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 3 times, but it was called 2 times'

tests['number of times called, failure, too many'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.times(3)).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 3 times, but it was called 4 times'

tests['number of times called: once, failure - too few'] = ->
	mock = mj.mock(new UnderTest())
	cb = -> mj.verify(mock, mj.once).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 1 times, but it was called 0 times'

tests['number of times called: twice, failure - too few'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.twice).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 2 times, but it was called 1 times'

tests['number of times called: thrice, failure - too few'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.thrice).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 3 times, but it was called 2 times'

tests['number of times called: never, but actually was called'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.never).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 0 times, but it was called 1 times'

tests['number of times called: once, failure - too many'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.once).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 1 times, but it was called 2 times'

tests['number of times called: twice, failure - too many'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.twice).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 2 times, but it was called 3 times'

tests['number of times called: thrice, failure - too many'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.thrice).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called exactly 3 times, but it was called 4 times'

tests['number of times called, at most'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mj.verify(mock, mj.atMost(6)).frob(1, 7)

tests['number of times called, at most, failure'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.atMost(3)).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called at most 3 times, but it was called 4 times'

tests['number of times called, at least'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mj.verify(mock, mj.atLeast(3)).frob(1, 7)

tests['number of times called, at least, failure'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.atLeast(6)).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called at least 6 times, but it was called 4 times'

tests['number of times called, range'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mj.verify(mock, mj.range(3, 5)).frob(1, 7)

tests['number of times called, range, too high'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.range(6, 19)).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called between 6 and 19 times, but it was called 4 times'

tests['number of times called, range, too low'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verify(mock, mj.range(1, 3)).frob(1, 7)
	assert.throws cb, (ex) ->
		ex.message == 'Expected UnderTest.frob(1, 7) to be called between 1 and 3 times, but it was called 4 times'

tests['verifyNoMoreInteractions'] = ->
	mock = mj.mock(new UnderTest())
	mj.verifyNoMoreInteractions(mock)

tests['verifyNoMoreInteractions failure'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verifyNoMoreInteractions(mock)
	assert.throws cb, (ex) ->
		ex.message == 'Expected:\n\tUnderTest.frob(1, 7) should not be called\nActual:\n\tUnderTest.frob(1, 7) was called 4 times'

tests['verifyZeroInteractions'] = ->
	mock = mj.mock(new UnderTest())
	mj.verifyZeroInteractions(mock)

tests['verifyZeroInteractions with setup'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1, 7).thenReturn 4
	mj.verifyZeroInteractions(mock)

tests['verifyZeroInteractions failure'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	mock.frob(1, 7)
	cb = -> mj.verifyZeroInteractions(mock)
	assert.throws cb, (ex) ->
		ex.message == 'Expected no interactions with UnderTest, but UnderTest.frob(1, 7) was called 4 times'

tests['matchers by position and failed non-matcher arg match'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1, mj.match((x) -> x % 6 == 1)).thenReturn(187)
	assert.equal mock.frob(2, 7), null

tests['matchers by position and failed matcher match'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(1, mj.match((x) -> x % 6 == 1)).thenReturn(187)
	assert.equal mock.frob(1, 8), null

tests['matchers by position'] = ->
	mock = mj.mock(new UnderTest())
	mj.when(mock).frob(mj.match((x) -> x == 1), mj.match((x) -> x % 6 == 1)).thenReturn(187)
	assert.equal mock.frob(1, 7), 187

tests['verify by matcher'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 7)
	mj.verify(mock).frob((mj.match((x) -> x == 1)), 7)

tests['verify by matcher but does not match'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(2, 7)
	assert.throws -> mj.verify(mock).frob((mj.match((x) -> x == 1)), 7)

tests['verify by matcher but non-matcher arg does not match'] = ->
	mock = mj.mock(new UnderTest())
	mock.frob(1, 8)
	assert.throws -> mj.verify(mock).frob((mj.match((x) -> x == 1)), 7)

count = 0
pass = 0
for k, v of tests
    count++
    try
        v()
        pass++
    catch ex
        console.error "#{k} failed: #{ex}"

console.log "#{pass}/#{count} tests pass"
if pass == count
    console.log "SUCCESS"
else
    console.log "FAILURE"
