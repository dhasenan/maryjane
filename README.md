MaryJane
========
A mock objects library for javascript.

Platform Support
================
I don't intend to exclude any platforms, but my development is all on Linux with Node.js. I will accept patches to fix broken functionality in any other environment, if they don't break Node.js.

I might extend platform support in the future, with the next likely target being Jurassic, but this is far from guaranteed.

Despite these warnings about platform support, there shouldn't be anything strange about MaryJane that would prevent you from using it in any reasonably compliant environment.

A Note on Types
===============
MaryJane takes a rather strong stance toward types. Specifically, you should deal with types that exist. If you dynamically add methods to your type, this should be accomplished in some global setup.

Regardless, there's almost no way to properly mock an object method that will be assigned during the course of a test. (Implementing that would eliminate any chance of multiplatform support.) So just don't, kay?

Usage
=====

Creating Mocks
--------------
MaryJane will create a mock from:

 * an existing object
 * an object prototype
 * a constructor

It will mock its methods and make a shallow copy of its fields. It will *not* run the constructor, even if you pass a constructor or a prototype. Since JavaScript objects typically get instance fields from the constructor, it's recommended that you pass in a newly constructed instance, such as: `MaryJane.mock(new ClassUnderTest())`. (This usage will call a constructor, but it isn't Mary Jane doing so.)

There's not much point in using an object prototype. It's identical to passing the constructor.

To create a mock:

	require('maryjane');

	var mock1 = mock(new MyObject());
	var mock2 = mock(ObjectWithUntrustedConstructor);
	var mock3 = mock(ObjectWithUntrustedConstructor.prototype);

Using Mocks
-----------
MaryJane uses the Arrange-Act-Assert system. Let's say you have a function that takes an apple from a tree and chucks it down a well:

	var iHateApples = function(appleTree, well)
	{
		var apple = appleTree.pluckApple();
		well.consume(apple);
	}

Let's look at the test:

	// Arrange -- how does the world look and act?
	var appleTree = mock(new AppleTree());
	var well = mock(new Well());
	var apple = new Apple();
	when(appleTree).pluckApple().thenReturn(apple);

	// Act: run the test method
	iHateApples(appleTree, well);

	// Assert: what happened?
	verify(well).consume(apple);


Let's look at that in more depth. We've already looked at creating mock objects, so the first couple lines should make sense. But let's check out the fourth line:

	when(appleTree).pluckApple().thenReturn(apple);

`when` is a MaryJane function that takes a mock object and returns an object ready to arrange a future method call. This object supports the same methods as your original object, but every method will return a method call object on which you can set some options.

Here's what you can do with the mock options:

 * `thenReturn`: return a particular value.
 * `thenThrow`: throw a given exception.
 * `thenDo`: run a callback. See the section on callbacks below.
 * `lax`: don't worry about arguments overmuch. If the caller supplied more arguments than you expected, that's just fine.

You can even chain these together:

	when(mock).frob(14)
		.thenReturn('ya think?')
		.thenThrow(new Error('Divide by Cucumber Exception'))
		.thenDo(function() { assert.fail(); });

Note that `lax` applies to the entire method call. If you want one response with lax matching and another with strict matching, you need to do that separately.

Okay, now you know how to set up a result. What about verifying that something has been called?

Just use the same process, but with `verify` rather than `when`:

	verify(well).consume(apple);

This will require that someone called `well.consume(apple)` at some point.

Currently, you can't check the number of times this was called. When this is implemented, it will appear as:

	verify(well, never).consume(apple);
	verify(well, once).consume(apple);
	verify(well, times(17)).consume(apple);
	verify(well, atLeast(17)).consume(apple);

Currently, you can't check that a mock had no interactions or no unverified interactions. When this is available, it will appear as:

	verifyNoMoreInteractions(well1, well2);
	verifyZeroInteractions(well3, well4);

Using Callbacks
---------------
When you supply a callback on a method with `thenDo`, the method you supply stands in for the called method.

Consider:

	var math = mock(new MathHelper());
	when(math).add(a, b).thenDo(function(a, b) { return a ^ b; });

This will replace the `add` function on `math` with one that returns the bitwise XOR of its operands. All the usual mock object accounting will hold, but the function you supply will be executed.

TODO
====
 * Verify number of times a method was called
 * verifyNoMoreInteractions, verifyZeroInteractions
 * Multiple expectations for methods (throw the first time, return null the second, return this the third time)
 * Ordering
 * Argument matchers
