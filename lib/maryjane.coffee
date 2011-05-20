# MaryJane: a mock object library supporting Arrange Act Assert syntax.

exports.mock = (type) ->
    if !type?
        throw new Error 'You must provide a type'
    new Mock(type)

exports.when = (mock) ->
    if !(mock instanceof Mock)
        throw new Error 'You can only use this with mock objects'
    if mock._mockInternals?
        return mock._mockInternals.newExpectation()
    else
        throw new Error 'Malformed mock object'

class MockInternals
    constructor: (@type, @mock) ->
        if @type == null or @type == undefined
            throw new Error 'You must provide a type'
        #console.log 'working on type %s', @type.constructor.toString()
        for key, value of @type
            addIfMethod(@mock, @type, key)
        @expectedMethodCalls = []
        @unexpectedMethodCalls = []
        @recording = false

    checkExpectedCall: (field, args) ->
        if @recording
            m = new MockOptions(@mock, field, args)
            @expectedMethodCalls.push m
            @recording = false
            return m
        for call in @expectedMethodCalls
            if call.matches(field, args)
                return call.execute(field, args)
        m = new MockOptions(@mock, field, args)
        @unexpectedMethodCalls.push m
        null

    newExpectation: ->
        @recording = true
        @mock

class Mock
    constructor: (type) ->
        if type == null or type == undefined
            throw new Error 'You must provide a type'
        @_mockInternals = new MockInternals(type, @)

addIfMethod = (mock, type, field) ->
    f = type[field]
    if typeof f == 'function'
        mock[field] = () ->
            t = mock._mockInternals.checkExpectedCall field, arguments
            #console.log 'outer wrapper returning %s', t.toString()
            return t

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
    check: (fn) ->
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

    throwUnexpectedMethod: (args) ->
        throw new UnexpectedMethodCallError('Unexpected method call: ' + @_name + '(' + args + ')\nExpected: ' + @_name + '(' + @_args + ')')

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


class UnexpectedMethodCallError extends Error
    constructor: (msg) ->
        super(msg)
