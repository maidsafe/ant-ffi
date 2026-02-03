/*
 * Thread-safe async callback helper for Lua FFI
 *
 * This library provides a thread-safe callback mechanism for UniFFI async
 * futures. LuaJIT callbacks are not thread-safe when called from other
 * threads, so we use this C shim with atomic operations instead.
 *
 * Build instructions:
 *   Windows (MSVC):  cl /LD /O2 async_helper.c /Fe:async_helper.dll
 *   Windows (MinGW): gcc -shared -O2 -o async_helper.dll async_helper.c
 *   Linux:           gcc -shared -fPIC -O2 -o libasync_helper.so async_helper.c
 *   macOS:           clang -shared -fPIC -O2 -o libasync_helper.dylib async_helper.c
 */

#include <stdint.h>
#include <stdatomic.h>

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default")))
#endif

/* Maximum number of concurrent futures we can track */
#define MAX_FUTURES 256

/* Storage for poll results - one slot per future */
static atomic_int poll_results[MAX_FUTURES];

/* Simple slot allocation tracking */
static atomic_int slot_allocated[MAX_FUTURES];

/*
 * The callback function that Rust will call.
 * This is thread-safe because it only uses atomic operations.
 *
 * @param callback_data  The slot index (0 to MAX_FUTURES-1)
 * @param poll_result    0 = ready, 1 = wake/poll again
 */
EXPORT void uniffi_async_callback(uint64_t callback_data, int8_t poll_result) {
    uint64_t slot = callback_data;
    if (slot < MAX_FUTURES) {
        atomic_store(&poll_results[slot], (int)poll_result);
    }
}

/*
 * Allocate a slot for tracking a future's poll result.
 * Returns the slot index, or -1 if no slots available.
 */
EXPORT int32_t async_helper_alloc_slot(void) {
    for (int i = 0; i < MAX_FUTURES; i++) {
        int expected = 0;
        if (atomic_compare_exchange_strong(&slot_allocated[i], &expected, 1)) {
            /* Initialize the result to "pending" (-1) */
            atomic_store(&poll_results[i], -1);
            return i;
        }
    }
    return -1; /* No slots available */
}

/*
 * Free a previously allocated slot.
 */
EXPORT void async_helper_free_slot(int32_t slot) {
    if (slot >= 0 && slot < MAX_FUTURES) {
        atomic_store(&slot_allocated[slot], 0);
        atomic_store(&poll_results[slot], -1);
    }
}

/*
 * Get the current poll result for a slot.
 * Returns: -1 = not yet called, 0 = ready, 1 = wake/poll again
 */
EXPORT int8_t async_helper_get_result(int32_t slot) {
    if (slot >= 0 && slot < MAX_FUTURES) {
        return (int8_t)atomic_load(&poll_results[slot]);
    }
    return -1;
}

/*
 * Reset the poll result for a slot (set to "pending").
 */
EXPORT void async_helper_reset_result(int32_t slot) {
    if (slot >= 0 && slot < MAX_FUTURES) {
        atomic_store(&poll_results[slot], -1);
    }
}

/*
 * Get the callback function pointer.
 * Lua can use this to pass to UniFFI poll functions.
 */
EXPORT void* async_helper_get_callback(void) {
    return (void*)&uniffi_async_callback;
}
