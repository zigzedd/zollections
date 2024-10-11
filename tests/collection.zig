const std = @import("std");
const zollections = @import("zollections");

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

test "simple collection" {
	const allocator = std.testing.allocator;

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
}

test "recursive free" {
	const allocator = std.testing.allocator;

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
}

test "custom struct deinit" {
	const allocator = std.testing.allocator;

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
}
