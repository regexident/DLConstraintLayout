# DLConstraintLayout

Open Source, **API compatible** replacement of **CAConstraint**/**CAConstraintLayoutManager** for **iOS**.

While Core Animation `CALayer`s on **OS X** support constraint-based layout handling (also known as **Auto Layout**), **iOS** lacks support for said technology, despite providing it for UIViews.

**DLConstraintLayout** aims to **fill that gap** by providing **drop-in replacements** for the missing [`CAConstraint`](https://developer.apple.com/library/mac/#documentation/GraphicsImaging/Reference/CAConstraint_class/Introduction/Introduction.html)/[`CAConstraintLayoutManager`](https://developer.apple.com/library/mac/#documentation/GraphicsImaging/Reference/CAConstraintLayoutManager_class/Introduction/Introduction.html) classes for iOS.

## Differences to [DLConstraintLayout++](https://github.com/regexident/DLConstraintLayoutPlusPlus) project

While **DLConstraintLayout++** provides the very same public API as [**DLConstraintLayout**](https://github.com/regexident/DLConstraintLayout), its internal implementations differs in that it makes use of Objective-C++.

Benchmarks showed **DLConstraintLayout++** being on average ~7x faster than **DLConstraintLayout**.

## How to use it

Let's assume for a moment that you have a `CALayer` hierarchy that you want to layout using **Auto Layout**.

On **OS X** you'd [end up with layout code](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/CoreAnimation_guide/BuildingaLayerHierarchy/BuildingaLayerHierarchy.html#//apple_ref/doc/uid/TP40004514-CH6-SW2) akin to this:

    CALayer *layer = ...;

    layer.layoutManager = [CAConstraintLayoutManager layoutManager];

    [layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY
												    relativeTo:@"superlayer"
                                                     attribute:kCAConstraintMidY]];

Alright, but how about **iOS**?

Well, all you'd need to do is this:

1. Link your project against **libDLConstraintLayout.a** (while keeping [this](http://developer.apple.com/library/mac/#qa/qa1490/_index.html) in mind) or use **CocoaPods**.
2. Add `#import <DLConstraintLayout/DLConstraintLayout.h>` to your layout controller's `.m` file.
3. **Copy & paste** your code that's using **OS X**'s `CAConstraint`s into your iOS project and:
4. Either: **Replace all occurences** of the `CA` prefix with `DLCL…` (and `kCA…` with `kDLCL…` respectively). (Regex substitution: `s/(?<=\bk?)CA(?=Constraint)/DLCL/g`)
5. Or: **Add** `-DDLCL_USE_NATIVE_CA_NAMESPACE` to your project's **Other C Flags** and just **use the code and prefixes as is. No changes necessary.**

The code **stays the same**!

For more info see the included iOS/OSX demos.

**That's it.**

## How it works

**DLConstraintLayout** makes this all possible by providing the classes `DLCLConstraint` and `DLCLConstraintLayoutManager` as 100% API compatible replacements for their **OS X** counterparts `CAConstraint` and `CAConstraintLayoutManager` respectively. It then utilizes [`@compatibility_alias`](http://developer.apple.com/library/ios/#documentation/DeveloperTools/gcc-4.2.1/gcc/compatibility_005falias.html) and conditional `#define`s in order to allow you to address them the same way you'd do with `CAConstraint` and `CAConstraintLayoutManager` respectively.

## iOS API safety

Before injecting its own layout logic into `CALayer` **DLConstraintLayout** will search for existing `CAConstraint` and `CAConstraintLayoutManager` classes and check them for API compatibility with their respective `DLCL…` counterparts.

Three scenarios are possible:

#### Scenario #1: No existing native classes found at runtime

If there simply exist no native `CAConstraint(LayoutManager)` classes, then **DLConstraintLayout** will just proceed to inject its logic into `CALayer`.

#### Scenario #2: Existing and API-compatible native classes found at runtime

If there however exist native `CAConstraint(LayoutManager)` classes and their APIs match those from their respective counterparts in **DLConstraintLayout**, then injection is aborted and the counterparts' `+(id)alloc;` methods instead switch to returning native instances instead. (Which is exactly what you witness when playing with the **DLConstraintLayoutDemoOSX** demo app, btw.)

#### Scenario #3: Existing but API-incompatible native classes found at runtime

Last but not least if there exist native `CAConstraint(LayoutManager)` classes and their APIs happen to mismatch (as one cannot foresee if Apple will design constrained `CALayer` layout on iOS the same as on OS X, if ever at all.), then **DLConstraintLayout** will throw a `DLCLConstraintLayoutClassCollision` exception in `CALayer+DLConstraintLayout`'s `+(void)load;` method, terminating the app.

## Demos

**DLConstraintLayout** contains an **iOS** demo target (**DLConstraintLayoutDemo**) as well as an **OS X** counterpart (**DLConstraintLayoutDemoOSX**) sharing the very same layout code ([`DLCLViewController.m`](https://github.com/regexident/DLConstraintLayout/blob/master/DLConstraintLayoutDemoShared/DLCLViewController.m)).

## ARC

**DLConstraintLayout** works with **manual** as well as **automatic reference counting (ARC)**.

## Dependencies

None.

## Creator

Vincent Esche ([@regexident](http://twitter.com/regexident))

## License

**DLConstraintLayout** is available under a **modified BSD-3 clause license** with the **additional requirement of attribution**. See the `LICENSE.txt` file for more info.