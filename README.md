MaryJane
========
A mock objects library for javascript, inspired heavily by Mockito. It uses the Arrange-Act-Assert pattern.

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

	when(turret).encounter(weightedCompanionCube)
		.thenReturn('Who are you?')
		.thenThrow(new Error('Divide by Cucumber Exception'))
		.thenDo(function() { assert.fail(); });

Note that `lax` applies to the entire method call. If you want one response with lax matching and another with strict matching, you need to do that separately.

With MaryJane, you can also specify a predicate rather than an exact argument to match:

	when(turret).shootAll(match(function(x) { return x.canBeShot(); }), 
						  match(function(y) { return y.containsPortal(); }))
		.thenReturn(foo);

Every time the `turret.shootAll` method is called, the functions can be evaluated. There is no guarantee as to the order.

Okay, now you know how to set up a result. What about verifying that something has been called?

Just use the same process, but with `verify` rather than `when`:

	verify(materialEmancipationGrid).consume(weightedCompanionCube); // NOOOOOOOOOOOO!

This will require that someone called `well.consume(apple)` at some point.

You can also verify the number of times something should be called:

	verify(murkyWater, never).consume(weightedCompanionCube);
	verify(lazor, once).fry(weightedStorageCube); // we also have 'twice' and 'thrice'
	verify(turret1, times(17)).fallThrough(orangePortal);
	verify(turret2, atLeast(17)).fallThrough(bluePortal);
	verify(plasmaBallOfDeath, atMost(3)).bounceOff(wall1);
	verify(redirectionCube, between(3, 7)).fry(unfortunateTurret);

You can also use a callback to match arguments, just like in the Arrange phase:

	verify(lazor).fry(match(function(x) { return x.name == 'Chell'; }));

And you can do that with some arguments and not others:

	verify(turret).shootAll(match(function(x) { return x.name == 'Chell'; }), wall1);

If you want to check that you've covered all the cases, or that a particular mock hasn't been used in this case:

	verifyNoMoreInteractions(weightedStorageSphere);
	verifyZeroInteractions(turret3);

Both of these ignore anything you did in the Arrange phase. For example, the following test will pass:

	when(portalGun).firePortal('up').thenReturn('You made a hole in the ceiling');
	verifyZeroInteractions(portalGun);

This is useful when you have an excessively complicated test, or when you use a common setup method that sets up some return values but this particular method does not make use of them.

Both of these can take multiple mocks:

	verifyZeroInteractions(turret1, turret2, weightedStorageCube);

Using Callbacks
---------------
When you supply a callback on a method with `thenDo`, the method you supply stands in for the called method.

Consider:

	var math = mock(new MathHelper());
	when(math).add(a, b).thenDo(function(a, b) { return a ^ b; });

This will replace the `add` function on `math` with one that returns the bitwise XOR of its operands. All the usual mock object accounting will hold, but the function you supply will be executed.

A Note on Types
===============
MaryJane takes a rather strong stance toward types. Specifically, you should deal with types that exist and are relatively static. If you dynamically add methods to your type, this should be accomplished in some global setup.

Regardless, there's almost no way to properly mock an object method that will be assigned during the course of a test. (I could probably do it, but not in JavaScript; I'd need to write a Node plugin.) So just don't, kay?

Platform Support
================
I don't intend to exclude any platforms, but my development is all on Linux with Node.js. I will accept patches to fix broken functionality in any other environment, if they don't break Node.js.

I might extend platform support in the future, with the next likely target being Jurassic, but this is far from guaranteed.

Despite these warnings about platform support, there shouldn't be anything strange about MaryJane that would prevent you from using it in any reasonably compliant environment.

TODO
====
 * Ordering
