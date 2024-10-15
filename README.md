<p align="center">
	<a href="https://code.zeptotech.net/zedd/zollections">
		<picture>
			<img alt="Zollections logo" width="150" src="https://code.zeptotech.net/zedd/zollections/raw/branch/main/logo.svg" />
		</picture>
	</a>
</p>

<h1 align="center">
	Zollections
</h1>

<h4 align="center">
	<a href="https://code.zeptotech.net/zedd/zollections">Documentation</a>
|
	<a href="https://zedd.zeptotech.net/zollections/api">API</a>
</h4>

<p align="center">
	Zig collections library
</p>

Zollections is part of [_zedd_](https://code.zeptotech.net/zedd), a collection of useful libraries for zig.

## Zollections

_Zollections_ is a collections library for Zig. It's made to ease memory management of dynamically allocated slices and elements.

## Versions

Zollections 0.1.1 is made and tested with zig 0.13.0.

## How to use

### Install

In your project directory:

```shell
$ zig fetch --save https://code.zeptotech.net/zedd/zollections/archive/v0.1.1.tar.gz
```

In `build.zig`:

```zig
// Add zollections dependency.
const zollections = b.dependency("zollections", .{
	.target = target,
	.optimize = optimize,
});
exe.root_module.addImport("zollections", zollections.module("zollections"));
```

### Examples

These examples are taken from tests in [`tests/collection.zig`](https://code.zeptotech.net/zedd/zollections/src/branch/main/tests/collection.zig).

#### Simple collection

```zig
// Allocate your slice.
const slice = try allocator.alloc(*u8, 3);
// Create your slice elements.
slice[0] = try allocator.create(u8);
slice[1] = try allocator.create(u8);
slice[2] = try allocator.create(u8);

// Create a collection with your slice of elements.
const collection = try zollections.Collection(u8).init(allocator, slice);
// Free your collection: your slice and all your elements will be freed.
defer collection.deinit();
```

#### Recursive free

```zig
// Create a pointer to a slice.
const slicePointer = try allocator.create([]*u8);

// Allocate your slice in the pointed slice.
slicePointer.* = try allocator.alloc(*u8, 3);
// Create slice elements.
slicePointer.*[0] = try allocator.create(u8);
slicePointer.*[1] = try allocator.create(u8);
slicePointer.*[2] = try allocator.create(u8);

// Allocate your slice or pointers to slices.
const slice = try allocator.alloc(*[]*u8, 1);
slice[0] = slicePointer;

// Create a collection with your slice of elements.
const collection = try zollections.Collection([]*u8).init(allocator, slice);
// Free your collection: your slice and all your slices and their elements will be freed.
defer collection.deinit();
```

#### Custom structure deinitialization

```zig

/// An example structure.
const ExampleStruct = struct {
	const Self = @This();

	allocator: std.mem.Allocator,
	buffer: []u8,

	/// Initialize a new example struct.
	pub fn init(bufSiz: usize) !Self
	{
		const allocator = std.testing.allocator;

		return .{
			.allocator = allocator,
			.buffer = try allocator.alloc(u8, bufSiz),
		};
	}

	/// Deinitialize the example struct.
	pub fn deinit(self: *Self) void
	{
		self.allocator.free(self.buffer);
	}
};

// Allocate your slice.
const slice = try allocator.alloc(*ExampleStruct, 3);
// Create your slice elements with custom structs and their inner init / deinit.
slice[0] = try allocator.create(ExampleStruct);
slice[0].* = try ExampleStruct.init(4);
slice[1] = try allocator.create(ExampleStruct);
slice[1].* = try ExampleStruct.init(8);
slice[2] = try allocator.create(ExampleStruct);
slice[2].* = try ExampleStruct.init(16);

// Create a collection with your slice of elements.
const collection = try zollections.Collection(ExampleStruct).init(allocator, slice);
// Free your collection: your slice and all your elements will be deinitialized and freed.
defer collection.deinit();

```
