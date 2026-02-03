package antffi

/*
#include <stdint.h>

typedef struct {
    uint64_t capacity;
    uint64_t len;
    uint8_t* data;
} RustBuffer;

typedef struct {
    int8_t code;
    RustBuffer error_buf;
} RustCallStatus;

// Client constructors (Async)
extern uint64_t uniffi_ant_ffi_fn_constructor_client_init();
extern uint64_t uniffi_ant_ffi_fn_constructor_client_init_local();
extern void uniffi_ant_ffi_fn_free_client(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_client(void* ptr, RustCallStatus* status);

// Client - Data Operations (Async)
extern uint64_t uniffi_ant_ffi_fn_method_client_data_put_public(void* ptr, RustBuffer data, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_data_get_public(void* ptr, RustBuffer addressHex);
extern uint64_t uniffi_ant_ffi_fn_method_client_data_put(void* ptr, RustBuffer data, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_data_get(void* ptr, void* dataMapChunk);
extern uint64_t uniffi_ant_ffi_fn_method_client_data_cost(void* ptr, RustBuffer data);

// Client - File Operations (Async)
extern uint64_t uniffi_ant_ffi_fn_method_client_file_upload_public(void* ptr, RustBuffer filePath, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_file_download_public(void* ptr, void* address, RustBuffer destPath);
extern uint64_t uniffi_ant_ffi_fn_method_client_file_upload(void* ptr, RustBuffer filePath, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_file_download(void* ptr, void* dataMapChunk, RustBuffer destPath);
extern uint64_t uniffi_ant_ffi_fn_method_client_file_cost(void* ptr, RustBuffer filePath);

// Client - Chunk Operations (Async)
extern uint64_t uniffi_ant_ffi_fn_method_client_chunk_put(void* ptr, RustBuffer data, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_chunk_get(void* ptr, void* address);

// Client - Pointer Operations (Async)
extern uint64_t uniffi_ant_ffi_fn_method_client_pointer_get(void* ptr, void* address);
extern uint64_t uniffi_ant_ffi_fn_method_client_pointer_put(void* ptr, void* pointer, RustBuffer payment);

// Client - GraphEntry Operations (Async)
extern uint64_t uniffi_ant_ffi_fn_method_client_graph_entry_get(void* ptr, void* address);
extern uint64_t uniffi_ant_ffi_fn_method_client_graph_entry_put(void* ptr, void* entry, RustBuffer payment);

// Client - Scratchpad Operations (Async)
extern uint64_t uniffi_ant_ffi_fn_method_client_scratchpad_get(void* ptr, void* address);
extern uint64_t uniffi_ant_ffi_fn_method_client_scratchpad_put(void* ptr, void* scratchpad, RustBuffer payment);

// Client - Register Operations (Async)
extern uint64_t uniffi_ant_ffi_fn_method_client_register_get(void* ptr, void* address);
extern uint64_t uniffi_ant_ffi_fn_method_client_register_create(void* ptr, void* owner, RustBuffer value, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_register_update(void* ptr, void* owner, RustBuffer value, RustBuffer payment);

// Client - Vault Operations (Async)
extern uint64_t uniffi_ant_ffi_fn_method_client_vault_get_user_data(void* ptr, void* secretKey);
extern uint64_t uniffi_ant_ffi_fn_method_client_vault_put_user_data(void* ptr, void* secretKey, RustBuffer payment, void* userData);

// Client - Archive Operations (Async)
extern uint64_t uniffi_ant_ffi_fn_method_client_archive_get_public(void* ptr, void* address);
extern uint64_t uniffi_ant_ffi_fn_method_client_archive_put_public(void* ptr, void* archive, RustBuffer payment);
*/
import "C"

import (
	"context"
	"runtime"
	"sync"
	"unsafe"
)

// PaymentOption represents payment options for network operations.
type PaymentOption struct {
	// Wallet is the wallet to use for payment (can be nil for free operations)
	Wallet *Wallet
}

// getPaymentBuffer serializes the payment option to a RustBuffer.
func getPaymentBuffer(payment *PaymentOption) C.RustBuffer {
	if payment == nil || payment.Wallet == nil {
		return C.RustBuffer{}
	}
	walletHandle := payment.Wallet.CloneHandle()
	if walletHandle == nil {
		return C.RustBuffer{}
	}
	return lowerPaymentOption(walletHandle)
}

// Client represents a connection to the Autonomi network.
type Client struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewClient creates a new client connected to the production network.
func NewClient(ctx context.Context) (*Client, error) {
	futureHandle := uint64(C.uniffi_ant_ffi_fn_constructor_client_init())
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}
	return newClient(ptr), nil
}

// NewClientLocal creates a new client connected to a local testnet.
func NewClientLocal(ctx context.Context) (*Client, error) {
	futureHandle := uint64(C.uniffi_ant_ffi_fn_constructor_client_init_local())
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}
	return newClient(ptr), nil
}

func newClient(handle unsafe.Pointer) *Client {
	c := &Client{handle: handle}
	runtime.SetFinalizer(c, (*Client).Free)
	return c
}

// Free releases the client resources.
func (c *Client) Free() {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.freed || c.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_client(c.handle, &status)
	c.freed = true
}

func (c *Client) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_client(c.handle, &status)
}

// CloneHandle returns a cloned handle for FFI operations.
func (c *Client) CloneHandle() unsafe.Pointer {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.freed {
		return nil
	}
	return c.cloneHandle()
}

// ========== Data Operations ==========

// UploadResult represents the result of uploading data to the network.
type UploadResult struct {
	// The price paid for the upload in tokens
	Price string
	// The hex-encoded data address where the data was stored
	Address string
}

// DataPutPublic uploads public data to the network.
// Returns an UploadResult with the price and address.
func (c *Client) DataPutPublic(ctx context.Context, data []byte, payment *PaymentOption) (*UploadResult, error) {
	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	dataBuffer := toRustBuffer(data)
	paymentBuffer := getPaymentBuffer(payment)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_data_put_public(cloned, dataBuffer, paymentBuffer))
	buf, err := pollRustBufferFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	// Deserialize UploadResult record
	rawBytes := fromRustBufferRaw(buf, true)
	reader := NewUniFFIReader(rawBytes)
	price := reader.ReadString()
	address := reader.ReadString()

	return &UploadResult{Price: price, Address: address}, nil
}

// DataGetPublic retrieves public data from the network by address.
func (c *Client) DataGetPublic(ctx context.Context, addressHex string) ([]byte, error) {
	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	addressBuffer := stringToRustBuffer(addressHex)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_data_get_public(cloned, addressBuffer))
	buf, err := pollRustBufferFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return fromRustBuffer(buf, true), nil
}

// DataPutResult represents the result of uploading private data.
type DataPutResult struct {
	// The cost paid for the upload in tokens
	Cost string
	// The data map chunk to retrieve the data
	DataMap *DataMapChunk
}

// DataPut uploads private (self-encrypted) data to the network.
// Returns a DataPutResult with the cost and data map.
func (c *Client) DataPut(ctx context.Context, data []byte, payment *PaymentOption) (*DataPutResult, error) {
	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	dataBuffer := toRustBuffer(data)
	paymentBuffer := getPaymentBuffer(payment)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_data_put(cloned, dataBuffer, paymentBuffer))
	buf, err := pollRustBufferFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	// Deserialize DataPutResult record (cost: String, data_map: Arc<DataMapChunk>)
	rawBytes := fromRustBufferRaw(buf, true)
	reader := NewUniFFIReader(rawBytes)
	cost := reader.ReadString()
	dataMapPtr := reader.ReadPointer()

	return &DataPutResult{
		Cost:    cost,
		DataMap: newDataMapChunk(dataMapPtr),
	}, nil
}

// DataGet retrieves private (self-encrypted) data from the network.
func (c *Client) DataGet(ctx context.Context, dataMapChunk *DataMapChunk) ([]byte, error) {
	if dataMapChunk == nil {
		return nil, ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	dataMapCloned := dataMapChunk.CloneHandle()
	if dataMapCloned == nil {
		return nil, ErrDisposed
	}

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_data_get(cloned, dataMapCloned))
	buf, err := pollRustBufferFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return fromRustBuffer(buf, true), nil
}

// DataCost calculates the cost to store data on the network.
func (c *Client) DataCost(ctx context.Context, data []byte) (string, error) {
	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return "", ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	dataBuffer := toRustBuffer(data)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_data_cost(cloned, dataBuffer))
	buf, err := pollRustBufferFuture(ctx, futureHandle)
	if err != nil {
		return "", err
	}

	return stringFromRustBuffer(buf), nil
}

// ========== File Operations ==========

// FileUploadPublic uploads a public file to the network.
// Returns the address where the file was stored.
func (c *Client) FileUploadPublic(ctx context.Context, filePath string, payment *PaymentOption) (string, error) {
	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return "", ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	filePathBuffer := stringToRustBuffer(filePath)
	paymentBuffer := getPaymentBuffer(payment)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_file_upload_public(cloned, filePathBuffer, paymentBuffer))
	buf, err := pollRustBufferFuture(ctx, futureHandle)
	if err != nil {
		return "", err
	}

	return stringFromRustBuffer(buf), nil
}

// FileDownloadPublic downloads a public file from the network.
func (c *Client) FileDownloadPublic(ctx context.Context, address *DataAddress, destPath string) error {
	if address == nil {
		return ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	addressCloned := address.CloneHandle()
	if addressCloned == nil {
		return ErrDisposed
	}
	destPathBuffer := stringToRustBuffer(destPath)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_file_download_public(cloned, addressCloned, destPathBuffer))
	return pollVoidFuture(ctx, futureHandle)
}

// FileUpload uploads a private (self-encrypted) file to the network.
// Returns a DataMapChunk that can be used to retrieve the file.
func (c *Client) FileUpload(ctx context.Context, filePath string, payment *PaymentOption) (*DataMapChunk, error) {
	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	filePathBuffer := stringToRustBuffer(filePath)
	paymentBuffer := getPaymentBuffer(payment)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_file_upload(cloned, filePathBuffer, paymentBuffer))
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return newDataMapChunk(ptr), nil
}

// FileDownload downloads a private (self-encrypted) file from the network.
func (c *Client) FileDownload(ctx context.Context, dataMapChunk *DataMapChunk, destPath string) error {
	if dataMapChunk == nil {
		return ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	dataMapCloned := dataMapChunk.CloneHandle()
	if dataMapCloned == nil {
		return ErrDisposed
	}
	destPathBuffer := stringToRustBuffer(destPath)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_file_download(cloned, dataMapCloned, destPathBuffer))
	return pollVoidFuture(ctx, futureHandle)
}

// FileCost calculates the cost to store a file on the network.
func (c *Client) FileCost(ctx context.Context, filePath string) (string, error) {
	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return "", ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	filePathBuffer := stringToRustBuffer(filePath)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_file_cost(cloned, filePathBuffer))
	buf, err := pollRustBufferFuture(ctx, futureHandle)
	if err != nil {
		return "", err
	}

	return stringFromRustBuffer(buf), nil
}

// ========== Chunk Operations ==========

// ChunkPut uploads a chunk to the network.
// Returns the chunk address.
func (c *Client) ChunkPut(ctx context.Context, data []byte, payment *PaymentOption) (*ChunkAddress, error) {
	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	dataBuffer := toRustBuffer(data)
	paymentBuffer := getPaymentBuffer(payment)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_chunk_put(cloned, dataBuffer, paymentBuffer))
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return newChunkAddress(ptr), nil
}

// ChunkGet retrieves a chunk from the network.
func (c *Client) ChunkGet(ctx context.Context, address *ChunkAddress) (*Chunk, error) {
	if address == nil {
		return nil, ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	addressCloned := address.CloneHandle()
	if addressCloned == nil {
		return nil, ErrDisposed
	}

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_chunk_get(cloned, addressCloned))
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return newChunk(ptr), nil
}

// ========== Pointer Operations ==========

// PointerGet retrieves a pointer from the network.
func (c *Client) PointerGet(ctx context.Context, address *PointerAddress) (*NetworkPointer, error) {
	if address == nil {
		return nil, ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	addressCloned := address.CloneHandle()
	if addressCloned == nil {
		return nil, ErrDisposed
	}

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_pointer_get(cloned, addressCloned))
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return newNetworkPointer(ptr), nil
}

// PointerPut stores a pointer on the network.
func (c *Client) PointerPut(ctx context.Context, pointer *NetworkPointer, payment *PaymentOption) error {
	if pointer == nil {
		return ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	pointerCloned := pointer.CloneHandle()
	if pointerCloned == nil {
		return ErrDisposed
	}
	paymentBuffer := getPaymentBuffer(payment)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_pointer_put(cloned, pointerCloned, paymentBuffer))
	return pollVoidFuture(ctx, futureHandle)
}

// ========== GraphEntry Operations ==========

// GraphEntryGet retrieves a graph entry from the network.
func (c *Client) GraphEntryGet(ctx context.Context, address *GraphEntryAddress) (*GraphEntry, error) {
	if address == nil {
		return nil, ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	addressCloned := address.CloneHandle()
	if addressCloned == nil {
		return nil, ErrDisposed
	}

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_graph_entry_get(cloned, addressCloned))
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return newGraphEntry(ptr), nil
}

// GraphEntryPut stores a graph entry on the network.
func (c *Client) GraphEntryPut(ctx context.Context, entry *GraphEntry, payment *PaymentOption) error {
	if entry == nil {
		return ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	entryCloned := entry.CloneHandle()
	if entryCloned == nil {
		return ErrDisposed
	}
	paymentBuffer := getPaymentBuffer(payment)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_graph_entry_put(cloned, entryCloned, paymentBuffer))
	return pollVoidFuture(ctx, futureHandle)
}

// ========== Scratchpad Operations ==========

// ScratchpadGet retrieves a scratchpad from the network.
func (c *Client) ScratchpadGet(ctx context.Context, address *ScratchpadAddress) (*Scratchpad, error) {
	if address == nil {
		return nil, ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	addressCloned := address.CloneHandle()
	if addressCloned == nil {
		return nil, ErrDisposed
	}

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_scratchpad_get(cloned, addressCloned))
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return newScratchpad(ptr), nil
}

// ScratchpadPut stores a scratchpad on the network.
func (c *Client) ScratchpadPut(ctx context.Context, scratchpad *Scratchpad, payment *PaymentOption) error {
	if scratchpad == nil {
		return ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	scratchpadCloned := scratchpad.CloneHandle()
	if scratchpadCloned == nil {
		return ErrDisposed
	}
	paymentBuffer := getPaymentBuffer(payment)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_scratchpad_put(cloned, scratchpadCloned, paymentBuffer))
	return pollVoidFuture(ctx, futureHandle)
}

// ========== Register Operations ==========

// RegisterGet retrieves a register from the network.
func (c *Client) RegisterGet(ctx context.Context, address *RegisterAddress) ([]byte, error) {
	if address == nil {
		return nil, ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	addressCloned := address.CloneHandle()
	if addressCloned == nil {
		return nil, ErrDisposed
	}

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_register_get(cloned, addressCloned))
	buf, err := pollRustBufferFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return fromRustBuffer(buf, true), nil
}

// RegisterCreate creates a new register on the network.
func (c *Client) RegisterCreate(ctx context.Context, owner *DerivedSecretKey, value []byte, payment *PaymentOption) (*RegisterAddress, error) {
	if owner == nil {
		return nil, ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	ownerCloned := owner.CloneHandle()
	if ownerCloned == nil {
		return nil, ErrDisposed
	}
	valueBuffer := toRustBuffer(value)
	paymentBuffer := getPaymentBuffer(payment)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_register_create(cloned, ownerCloned, valueBuffer, paymentBuffer))
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return newRegisterAddress(ptr), nil
}

// RegisterUpdate updates an existing register on the network.
func (c *Client) RegisterUpdate(ctx context.Context, owner *DerivedSecretKey, value []byte, payment *PaymentOption) error {
	if owner == nil {
		return ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	ownerCloned := owner.CloneHandle()
	if ownerCloned == nil {
		return ErrDisposed
	}
	valueBuffer := toRustBuffer(value)
	paymentBuffer := getPaymentBuffer(payment)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_register_update(cloned, ownerCloned, valueBuffer, paymentBuffer))
	return pollVoidFuture(ctx, futureHandle)
}

// ========== Vault Operations ==========

// VaultGetUserData retrieves user data from a vault.
func (c *Client) VaultGetUserData(ctx context.Context, secretKey *VaultSecretKey) (*UserData, error) {
	if secretKey == nil {
		return nil, ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	secretKeyCloned := secretKey.CloneHandle()
	if secretKeyCloned == nil {
		return nil, ErrDisposed
	}

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_vault_get_user_data(cloned, secretKeyCloned))
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return newUserData(ptr), nil
}

// VaultPutUserData stores user data in a vault.
func (c *Client) VaultPutUserData(ctx context.Context, secretKey *VaultSecretKey, payment *PaymentOption, userData *UserData) error {
	if secretKey == nil || userData == nil {
		return ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	secretKeyCloned := secretKey.CloneHandle()
	if secretKeyCloned == nil {
		return ErrDisposed
	}
	userDataCloned := userData.CloneHandle()
	if userDataCloned == nil {
		return ErrDisposed
	}
	paymentBuffer := getPaymentBuffer(payment)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_vault_put_user_data(cloned, secretKeyCloned, paymentBuffer, userDataCloned))
	return pollVoidFuture(ctx, futureHandle)
}

// ========== Archive Operations ==========

// ArchiveGetPublic retrieves a public archive from the network.
func (c *Client) ArchiveGetPublic(ctx context.Context, address *ArchiveAddress) (*PublicArchive, error) {
	if address == nil {
		return nil, ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	addressCloned := address.CloneHandle()
	if addressCloned == nil {
		return nil, ErrDisposed
	}

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_archive_get_public(cloned, addressCloned))
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return newPublicArchive(ptr), nil
}

// ArchivePutPublic stores a public archive on the network.
// Returns the archive address.
func (c *Client) ArchivePutPublic(ctx context.Context, archive *PublicArchive, payment *PaymentOption) (*ArchiveAddress, error) {
	if archive == nil {
		return nil, ErrNilPointer
	}

	c.mu.Lock()
	if c.freed {
		c.mu.Unlock()
		return nil, ErrDisposed
	}
	cloned := c.cloneHandle()
	c.mu.Unlock()

	archiveCloned := archive.CloneHandle()
	if archiveCloned == nil {
		return nil, ErrDisposed
	}
	paymentBuffer := getPaymentBuffer(payment)

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_archive_put_public(cloned, archiveCloned, paymentBuffer))
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return newArchiveAddress(ptr), nil
}
