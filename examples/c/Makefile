# Autonomi C API Examples
#
# Usage:
#   make          - Build examples (must run 'make setup' first)
#   make setup    - Build the Rust library and generate C headers
#   make clean    - Remove built examples
#   make run      - Build and run self_encryption example

RUST_DIR := ../../rust
LIB_DIR := $(RUST_DIR)/target/release
HEADER_DIR := $(RUST_DIR)/output

CC := clang
CFLAGS := -I$(HEADER_DIR) -Wall
LDFLAGS := -L$(LIB_DIR) -lant_ffi

# macOS-specific frameworks
UNAME := $(shell uname)
ifeq ($(UNAME), Darwin)
    LDFLAGS += -framework Security -framework SystemConfiguration -framework CoreFoundation -liconv -lresolv
endif
ifeq ($(UNAME), Linux)
    LDFLAGS += -lm -lpthread -ldl
endif

EXAMPLES := self_encryption

.PHONY: all setup clean run

all: $(EXAMPLES)

self_encryption: self_encryption.c $(HEADER_DIR)/ant_ffiFFI.h $(LIB_DIR)/libant_ffi.a
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

$(LIB_DIR)/libant_ffi.a:
	@echo "Error: Library not built. Run 'make setup' first."
	@exit 1

$(HEADER_DIR)/ant_ffiFFI.h:
	@echo "Error: Headers not generated. Run 'make setup' first."
	@exit 1

setup:
	@echo "Building Rust library..."
	cd $(RUST_DIR) && cargo build --release -p ant-ffi
	@echo "Generating C headers..."
	cd $(RUST_DIR) && cargo run -p uniffi-bindgen-swift -- \
		target/release/libant_ffi.a \
		output/ \
		--headers \
		--modulemap \
		--module-name ant_ffiFFI
	@echo "Done! Now run 'make' to build examples."

clean:
	rm -f $(EXAMPLES)

run: self_encryption
	./self_encryption
