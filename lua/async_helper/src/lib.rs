//! Thread-safe async callback helper for Lua FFI
//!
//! This library provides a thread-safe callback mechanism for UniFFI async
//! futures. LuaJIT callbacks are not thread-safe when called from other
//! threads, so we use this Rust shim with atomic operations instead.

use std::sync::atomic::{AtomicI32, Ordering};

/// Maximum number of concurrent futures we can track
const MAX_FUTURES: usize = 256;

/// Storage for poll results - one slot per future
/// -1 = pending, 0 = ready, 1 = wake/poll again
static POLL_RESULTS: [AtomicI32; MAX_FUTURES] = {
    const INIT: AtomicI32 = AtomicI32::new(-1);
    [INIT; MAX_FUTURES]
};

/// Slot allocation tracking
static SLOT_ALLOCATED: [AtomicI32; MAX_FUTURES] = {
    const INIT: AtomicI32 = AtomicI32::new(0);
    [INIT; MAX_FUTURES]
};

/// The callback function that Rust will call.
/// This is thread-safe because it only uses atomic operations.
///
/// # Arguments
/// * `callback_data` - The slot index (0 to MAX_FUTURES-1)
/// * `poll_result` - 0 = ready, 1 = wake/poll again
#[no_mangle]
pub extern "C" fn uniffi_async_callback(callback_data: u64, poll_result: i8) {
    let slot = callback_data as usize;
    if slot < MAX_FUTURES {
        POLL_RESULTS[slot].store(poll_result as i32, Ordering::SeqCst);
    }
}

/// Allocate a slot for tracking a future's poll result.
/// Returns the slot index, or -1 if no slots available.
#[no_mangle]
pub extern "C" fn async_helper_alloc_slot() -> i32 {
    for i in 0..MAX_FUTURES {
        if SLOT_ALLOCATED[i]
            .compare_exchange(0, 1, Ordering::SeqCst, Ordering::SeqCst)
            .is_ok()
        {
            // Initialize the result to "pending" (-1)
            POLL_RESULTS[i].store(-1, Ordering::SeqCst);
            return i as i32;
        }
    }
    -1 // No slots available
}

/// Free a previously allocated slot.
#[no_mangle]
pub extern "C" fn async_helper_free_slot(slot: i32) {
    if slot >= 0 && (slot as usize) < MAX_FUTURES {
        let slot = slot as usize;
        SLOT_ALLOCATED[slot].store(0, Ordering::SeqCst);
        POLL_RESULTS[slot].store(-1, Ordering::SeqCst);
    }
}

/// Get the current poll result for a slot.
/// Returns: -1 = not yet called, 0 = ready, 1 = wake/poll again
#[no_mangle]
pub extern "C" fn async_helper_get_result(slot: i32) -> i8 {
    if slot >= 0 && (slot as usize) < MAX_FUTURES {
        POLL_RESULTS[slot as usize].load(Ordering::SeqCst) as i8
    } else {
        -1
    }
}

/// Reset the poll result for a slot (set to "pending").
#[no_mangle]
pub extern "C" fn async_helper_reset_result(slot: i32) {
    if slot >= 0 && (slot as usize) < MAX_FUTURES {
        POLL_RESULTS[slot as usize].store(-1, Ordering::SeqCst);
    }
}

/// Get the callback function pointer.
/// Lua can use this to pass to UniFFI poll functions.
#[no_mangle]
pub extern "C" fn async_helper_get_callback() -> *const () {
    uniffi_async_callback as *const ()
}
