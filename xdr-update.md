# XDR update: SCEnvMetaEntry interface version

The Stellar XDR spec changed `SCEnvMetaEntry`'s `interface_version` from a single `uint64` to a struct with two `uint32` fields:

```xdr
union SCEnvMetaEntry switch (SCEnvMetaKind kind) {
  case SC_ENV_META_KIND_INTERFACE_VERSION:
    struct {
      uint32 protocol;
      uint32 preRelease;
    } interfaceVersion;
};
```

`XdrSCEnvMetaEntry` still uses the old `uint64` format. It must be updated to decode the two `uint32` fields separately. `SorobanContractInfo.envInterfaceVersion` should be replaced by separate protocol and pre-release version fields.
