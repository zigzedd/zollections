const std = @import("std");

/// Collection of pointers of a certain type.
/// A collection manages memory of the contained type.
pub fn Collection(comptime T: anytype) type
{
	return struct {
		const Self = @This();

		/// The used allocator.
		allocator: std.mem.Allocator,
		/// Items contained by the collection.
		items: []*T,

		/// Initialize a new collection of values.
		/// Values are now owned by the collection and will free them when it is deinitialized.
		/// The allocator must be the one that manages the slice and its items.
		pub fn init(allocator: std.mem.Allocator, values: []*T) Self
		{
			return .{
				.allocator = allocator,
				// Store given values in items slice.
				.items = values,
			};
		}

		/// Free any pointer value.
		fn freeAnyPointer(self: *Self, pointer: anytype) void
		{
			// Get type info of the current pointer.
			const pointedTypeInfo = @typeInfo(@TypeOf(pointer.*));

			switch (pointedTypeInfo)
			{
				.Struct, .Enum, .Union, .Opaque => {
					// If type is a container with a deinit, run deinit.
					if (@hasDecl(@TypeOf(pointer.*), "deinit"))
						{ // The container has a specific deinit, running it.
							pointer.deinit();
							//TODO implement something like that.
							//switch (@TypeOf(pointer.deinit).@"fn".return_type)
							//{
							//	.ErrorUnion => {
							//		try pointer.deinit();
							//	},
							//	else => {
							//		pointer.deinit();
							//	},
							//}
						}
				},
				.Pointer => {
					// It's a simple pointer, freeing its value recursively.
					self.freeAnyValue(pointer.*);
				},
				else => {
					// Otherwise, we consider it as a simple value, there is nothing to free.
				},
			}

			// Free the current pointer.
			self.allocator.destroy(pointer);
		}

		/// Free any value.
		fn freeAnyValue(self: *Self, value: anytype) void
		{
			// Get type info of the current pointer.
			const typeInfo = @typeInfo(@TypeOf(value));

			switch (typeInfo)
			{
				.Pointer => |pointerInfo| {
					// Can be a slice or a simple pointer.
					if (pointerInfo.size == .One)
						{ // It's a simple pointer, freeing its value recursively.
							self.freeAnyPointer(value);
						}
					else
						{ // It's a slice, free every item then free it.
							for (value) |item|
							{ // For each item, free it recursively.
								self.freeAnyValue(item);
							}

							// Free the current pointer.
							self.allocator.free(value);
						}
				},
				else => {
					// Otherwise, we consider it as a simple value, nothing to free.
				},
			}
		}

		/// Deinitialize the collection of values and all its values.
		pub fn deinit(self: *Self) void
		{
			// Deinitialize all items.
			for (self.items) |item|
			{ // For each items, try to free it.
				self.freeAnyPointer(item);
			}

			// Free items slice.
			self.allocator.free(self.items);
		}
	};
}
