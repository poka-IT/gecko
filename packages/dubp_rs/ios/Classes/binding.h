#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * A Dart_CObject is used for representing Dart objects as native C
 * data outside the Dart heap. These objects are totally detached from
 * the Dart heap. Only a subset of the Dart objects have a
 * representation as a Dart_CObject.
 *
 * The string encoding in the 'value.as_string' is UTF-8.
 *
 * All the different types from dart:typed_data are exposed as type
 * kTypedData. The specific type from dart:typed_data is in the type
 * field of the as_typed_data structure. The length in the
 * as_typed_data structure is always in bytes.
 *
 * The data for kTypedData is copied on message send and ownership remains with
 * the caller. The ownership of data for kExternalTyped is passed to the VM on
 * message send and returned when the VM invokes the
 * Dart_WeakPersistentHandleFinalizer callback; a non-NULL callback must be
 * provided.
 */
typedef struct DartCObject DartCObject;
enum DartCObjectType
#ifdef __cplusplus
    : int32_t
#endif // __cplusplus
{
  DartNull = 0,
  DartBool = 1,
  DartInt32 = 2,
  DartInt64 = 3,
  DartDouble = 4,
  DartString = 5,
  DartArray = 6,
  DartTypedData = 7,
  DartExternalTypedData = 8,
  DartSendPort = 9,
  DartCapability = 10,
  DartUnsupported = 11,
  DartNumberOfTypes = 12,
};
#ifndef __cplusplus
typedef int32_t DartCObjectType;
#endif // __cplusplus

enum DartTypedDataType
#ifdef __cplusplus
    : int32_t
#endif // __cplusplus
{
  kByteData = 0,
  kInt8 = 1,
  kUint8 = 2,
  kUint8Clamped = 3,
  kInt16 = 4,
  kUint16 = 5,
  kInt32 = 6,
  kUint32 = 7,
  kInt64 = 8,
  kUint64 = 9,
  kFloat32 = 10,
  kFloat64 = 11,
  kFloat32x4 = 12,
  kInvalid = 13,
};
#ifndef __cplusplus
typedef int32_t DartTypedDataType;
#endif // __cplusplus

typedef void *RuntimePtr;

/**
 * A port is used to send or receive inter-isolate messages
 */
typedef int64_t DartPort;

typedef struct DartNativeSendPort
{
  DartPort id;
  DartPort origin_id;
} DartNativeSendPort;

typedef struct DartNativeCapability
{
  int64_t id;
} DartNativeCapability;

typedef struct DartNativeArray
{
  intptr_t length;
  DartCObject **values;
} DartNativeArray;

typedef struct DartNativeTypedData
{
  DartTypedDataType type_;
  intptr_t length;
  uint8_t *values;
} DartNativeTypedData;

typedef struct _DartWeakPersistentHandle
{
  uint8_t _unused[0];
} _DartWeakPersistentHandle;

typedef _DartWeakPersistentHandle *DartWeakPersistentHandle;

typedef void (*DartWeakPersistentHandleFinalizer)(void *isolate_callback_data, DartWeakPersistentHandle handle, void *peer);

typedef struct DartNativeExternalTypedData
{
  DartTypedDataType type_;
  intptr_t length;
  uint8_t *data;
  void *peer;
  DartWeakPersistentHandleFinalizer callback;
} DartNativeExternalTypedData;

typedef union DartCObjectValue {
  bool as_bool;
  int32_t as_int32;
  int64_t as_int64;
  double as_double;
  char *as_string;
  DartNativeSendPort as_send_port;
  DartNativeCapability as_capability;
  DartNativeArray as_array;
  DartNativeTypedData as_typed_data;
  DartNativeExternalTypedData as_external_typed_data;
  uint64_t _bindgen_union_align[5];
} DartCObjectValue;

typedef struct DartCObject
{
  DartCObjectType type_;
  DartCObjectValue value;
} DartCObject;

/**
 *  Posts a message on some port. The message will contain the
 *  Dart_CObject object graph rooted in 'message'.
 *
 *  While the message is being sent the state of the graph of
 *  Dart_CObject structures rooted in 'message' should not be accessed,
 *  as the message generation will make temporary modifications to the
 *  data. When the message has been sent the graph will be fully
 *  restored.
 *
 *  port_id The destination port.
 *  message The message to send.
 *
 *  return true if the message was posted.
 */
typedef bool (*DartPostCObjectFnPtr)(DartPort port_id, DartCObject *message);

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

void change_dewif_secret_code(int64_t port,
                              const char *dewif,
                              const char *old_secret_code,
                              uint32_t member_wallet,
                              uint32_t secret_code_type,
                              int64_t system_memory);

void gen_dewif(int64_t port,
               const char *currency,
               uint32_t language,
               const char *mnemonic,
               uint32_t member_wallet,
               uint32_t secret_code_type,
               int64_t system_memory,
               uint32_t wallet_type);

void gen_dewif_from_legacy(int64_t port,
                           const char *currency,
                           const char *salt,
                           const char *password,
                           uint32_t member_wallet,
                           uint32_t secret_code_type,
                           int64_t system_memory);

void gen_mnemonic(int64_t port, uint32_t language);

void get_bip32_dewif_accounts_pubkeys(int64_t port,
                                      const char *currency,
                                      const char *dewif,
                                      const char *secret_code,
                                      uint32_t accounts_indexs_len,
                                      const uint32_t *accounts_indexs);

void get_dewif_meta(int64_t port,
                    const char *dewif,
                    uint32_t member_wallet,
                    uint32_t secret_code_type);

void get_dewif_pubkey(int64_t port, const char *currency, const char *dewif, const char *pin);

int32_t get_dewif_secret_code_len(const char *dewif,
                                  uint32_t member_wallet,
                                  uint32_t secret_code_type);

void get_legacy_pubkey(int64_t port, const char *salt, const char *password);

void mnemonic_to_pubkey(int64_t port, uint32_t language, const char *mnemonic_phrase);

void sign(int64_t port, const char *currency, const char *dewif, const char *pin, const char *msg);

void sign_bip32_transparent(int64_t port,
                            uint32_t account_index,
                            const char *currency,
                            const char *dewif,
                            const char *secret_code,
                            const char *msg);

void sign_legacy(int64_t port, const char *salt, const char *password, const char *msg);

void sign_several(int64_t port,
                  const char *currency,
                  const char *dewif,
                  const char *pin,
                  uint32_t msgs_len,
                  const char *const *msgs);

void sign_several_bip32_transparent(int64_t port,
                                    uint32_t account_index,
                                    const char *currency,
                                    const char *dewif,
                                    const char *pin,
                                    uint32_t msgs_len,
                                    const char *const *msgs);

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus
