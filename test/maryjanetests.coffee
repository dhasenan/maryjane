mj = require 'maryjane'
assert = require 'assert'

class UnderTest
    frob: (a, b) ->
        throw 'DIVIDE BY CUCUMBER ERROR'

    fizz: (a) ->
        a + 17

exports['regurgitate an expected answer'] = ->
    mock = mj.mock(new UnderTest())
    mj.when(mock).frob(1, 7).thenReturn 15
    assert.eql mock.frob(1, 7), 15

exports['leave the original type alone'] = ->
    b = new UnderTest()
    assert.throws((-> b.frob(1, 7)), 'DIVIDE BY CUCUMBER ERROR')

exports['return null by default'] = ->
    b = mj.mock(new UnderTest())
    assert.eql b._mockInternals.expectedMethodCalls.length, 0
    assert.isNull b.frob(1, 7)
