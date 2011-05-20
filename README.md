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



TODO
====
 * Verify number of times a method was called
 * verifyNoMoreInteractions, verifyZeroInteractions
 * Multiple expectations for methods (throw the first time, return null the second, return this the third time)
 * Ordering
 * Argument matchers
