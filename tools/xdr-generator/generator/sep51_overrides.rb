# SEP-0051 (XDR-JSON) renderings for the types the specification gives a form of
# their own, rather than the form their XDR shape would imply.
#
# Two registries, split by how the type reaches the generated Dart.
#
# SEP51_TYPEDEF_RENDERERS is keyed by the *pre-override* generated name of a
# typedef -- the name before TYPE_OVERRIDES collapses it. Four typedefs have no
# Dart class of their own (ContractID and PoolID collapse onto XdrHash,
# AssetCode4 and AssetCode12 onto Uint8List), so a field declared with one is
# indistinguishable at the Dart type level from a field declared with the type
# it collapsed onto. Keying on the typedef's identity, resolved from the AST,
# is what keeps ContractID rendering as a C-strkey where Hash renders as hex.
#
# The registry is consulted at every struct field and every union arm. It fails
# closed: a future .x revision adding another field of a registered typedef gets
# the right rendering with no further edit, and a registered key that matches no
# typedef in the .x raises rather than being silently ignored.
#
# SEP51_TYPE_RENDERERS is keyed by the generated Dart class name, for the types
# that do exist as classes and still need a rendering of their own.
#
# Each typedef entry supplies two lambdas emitting Dart expressions:
#   to:   given an accessor expression, the quoted type name and the quoted key
#         (or 'null'), yields the JSON value
#   from: given a JSON value expression, the quoted type name and the quoted key
#         (or 'null'), yields the Dart value
#
# Each type entry supplies:
#   to:   given the public type name, either one expression or the lines of a
#         statement body, yielding the JSON value
#   from: given a context, the lines of a statement body reading the Dart value.
#         The context carries :class_name, :public_name, :result_type -- the
#         type the body returns -- and :build, which turns constructor arguments
#         into the expression that builds the instance. On a union base :build
#         yields the caller's `constructor`, so a hand-written wrapper narrows
#         the rendering to its own subclass; everywhere else it names the class.
#
# and, on either registry, the imports those expressions need, relative to
# lib/src/xdr/.

SEP51_STRKEY_IMPORT = "../key_pair.dart".freeze

# Byte widths of the strkey payloads SEP-0051 renders. The strkey codec verifies
# the version byte and the checksum but not the width, so a value of the right
# kind and the wrong length decodes cleanly and would build an instance the
# binary encoder then writes as malformed XDR.
SEP51_STRKEY_KEY_BYTES = 32       # G, T, X, C and L: one 32-byte key or hash
SEP51_STRKEY_MUXED_BYTES = 40     # M: the key, then the subaccount id
SEP51_STRKEY_BALANCE_BYTES = 33   # B: the discriminant tag, then the hash

# The two widths an asset code is declared with.
SEP51_ASSET_CODE4_BYTES = 4
SEP51_ASSET_CODE12_BYTES = 12

# Emits a call that resolves a strkey to its raw bytes, reporting a malformed
# strkey under the XDR-JSON error contract rather than as the codec's own error.
def sep51_strkey_from(decoder, value, type, key, length: nil)
  bound = length.nil? ? '' : ", expectedLength: #{length}"
  "XdrJsonHelper.readStrKey(#{value}, type: #{type}, key: #{key}, " \
    "decode: #{decoder}#{bound})"
end

SEP51_TYPEDEF_RENDERERS = {
  # SEP-0051 renders a contract identifier as a C-strkey, never as hex.
  "XdrContractID" => {
    to: ->(accessor, _type, _key) { "StrKey.encodeContractId(#{accessor}.hash)" },
    from: lambda { |value, type, key|
      "XdrHash(#{sep51_strkey_from('StrKey.decodeContractId', value, type, key,
                                   length: SEP51_STRKEY_KEY_BYTES)})"
    },
    imports: [SEP51_STRKEY_IMPORT],
  },

  # A liquidity pool identifier renders as an L-strkey.
  "XdrPoolID" => {
    to: ->(accessor, _type, _key) { "StrKey.encodeLiquidityPoolId(#{accessor}.hash)" },
    from: lambda { |value, type, key|
      "XdrHash(#{sep51_strkey_from('StrKey.decodeLiquidityPoolId', value, type, key,
                                   length: SEP51_STRKEY_KEY_BYTES)})"
    },
    imports: [SEP51_STRKEY_IMPORT],
  },

  # An asset code is opaque bytes carrying an ASCII code with trailing NUL
  # padding. The padding is not part of the value, so it is trimmed on the way
  # out and restored on the way in.
  "XdrAssetCode4" => {
    to: lambda { |accessor, type, key|
      "XdrJsonHelper.assetCode4(#{accessor}, type: #{type}, key: #{key})"
    },
    from: lambda { |value, type, key|
      "XdrJsonHelper.readAssetCode4(#{value}, type: #{type}, key: #{key})"
    },
    imports: [],
  },

  "XdrAssetCode12" => {
    to: lambda { |accessor, type, key|
      "XdrJsonHelper.assetCode12(#{accessor}, type: #{type}, key: #{key})"
    },
    from: lambda { |value, type, key|
      "XdrJsonHelper.readAssetCode12(#{value}, type: #{type}, key: #{key})"
    },
    imports: [],
  },
}.freeze

# Builds the pair of bodies for a 128- or 256-bit integer type, which SEP-0051
# renders as one base-10 decimal string rather than as an object of its limbs.
# The most significant limb of a signed type carries the sign; the rest are
# unsigned, which is how the .x declares them.
def sep51_parts_renderer(limbs, signed:)
  count = limbs.length
  {
    to: lambda { |public_name|
      reads = limbs.map { |field, accessor| "_#{field}.#{accessor}" }.join(', ')
      "XdrJsonHelper.partsToDecimalString(<BigInt>[#{reads}], " \
        "signed: #{signed}, type: '#{public_name}')"
    },
    from: lambda { |context|
      wrapped = limbs.each_with_index.map do |(_field, accessor), index|
        "#{accessor == 'int64' ? 'XdrInt64' : 'XdrUint64'}(limbs[#{index}])"
      end
      [
        "final List<BigInt> limbs = XdrJsonHelper.decimalStringToParts(",
        "    value, limbCount: #{count}, signed: #{signed}, " \
          "type: '#{context[:public_name]}');",
        "return #{context[:build].call(wrapped.join(', '))};",
      ]
    },
    imports: [],
  }
end

# One arm of a union SEP-0051 renders as a bare strkey.
#
#   member - the discriminant member the arm is declared under
#   field  - the Dart member the arm's value lives in
#   prefix - the leading character of the strkey the arm renders as, which is
#            what the reader dispatches on before it knows which codec applies
#   to     - given the accessor and the quoted type name, the expression
#            yielding the strkey
#   from   - given the JSON value expression and the quoted type name, the
#            expression yielding the value assigned back to the arm
Sep51StrKeyArm = Struct.new(:member, :field, :prefix, :to, :from, keyword_init: true)

# An arm holding a key or hash of its own, rendered by one strkey codec.
#
# payload names the member the raw bytes live in, and wrapper the class built
# around them on the way back.
def sep51_strkey_arm(member:, field:, prefix:, codec:, wrapper:, payload:,
                     length: SEP51_STRKEY_KEY_BYTES)
  Sep51StrKeyArm.new(
    member: member,
    field: field,
    prefix: prefix,
    to: ->(accessor, _type) { "StrKey.encode#{codec}(#{accessor}.#{payload})" },
    from: lambda { |value, type|
      "#{wrapper}(#{sep51_strkey_from("StrKey.decode#{codec}", value, type, 'null',
                                      length: length)})"
    },
  )
end

# An arm whose declared type carries the rendering itself, so both directions
# delegate to it and neither restates the strkey kind.
def sep51_delegating_arm(member:, field:, prefix:, type:)
  Sep51StrKeyArm.new(
    member: member,
    field: field,
    prefix: prefix,
    to: ->(accessor, _type) { "#{accessor}.toXdrJsonValue()" },
    from: ->(value, _type) { "#{type}.fromXdrJsonValue(#{value})" },
  )
end

# An arm declared with one of the collapsed typedefs, which takes the rendering
# already registered for that typedef rather than restating it.
def sep51_typedef_arm(member:, field:, prefix:, typedef:)
  renderer = SEP51_TYPEDEF_RENDERERS.fetch(typedef)
  Sep51StrKeyArm.new(
    member: member,
    field: field,
    prefix: prefix,
    to: ->(accessor, type) { renderer[:to].call(accessor, type, 'null') },
    from: ->(value, type) { renderer[:from].call(value, type, 'null') },
  )
end

# The prefixes a union accepts, as they read in an error message.
def sep51_prefix_list(arms)
  prefixes = arms.map(&:prefix)
  return prefixes.first if prefixes.length == 1

  "#{prefixes[0..-2].join(', ')} or #{prefixes.last}"
end

# Builds the pair of bodies for a union whose arms each render as a bare strkey.
#
# The writer switches on the discriminant, as the shape-derived rendering does.
# The reader has no discriminant to switch on -- the arm is not named by a key
# -- so it dispatches on the leading character of the strkey, which is what
# distinguishes the kinds from one another.
def sep51_strkey_union_renderer(discriminant, arms)
  expected = sep51_prefix_list(arms)
  {
    to: lambda { |public_name|
      quoted = "'#{public_name}'"
      lines = ['switch (discriminant) {']
      arms.each do |arm|
        lines << "  case #{discriminant}.#{arm.member}:"
        lines << "    return #{arm.to.call("_#{arm.field}!", quoted)};"
      end
      lines << '}'
      lines << "XdrJsonHelper.fail(#{quoted},"
      lines << "    'holds the unknown discriminant ${discriminant.value}');"
      lines
    },
    from: lambda { |context|
      quoted = "'#{context[:public_name]}'"
      lines = ["switch (XdrJsonHelper.readStrKeyPrefix(value, type: #{quoted})) {"]
      arms.each_with_index do |arm, index|
        local = "arm#{index}"
        lines << "  case '#{arm.prefix}':"
        lines << "    final #{context[:result_type]} #{local} = " \
                 "#{context[:build].call("#{discriminant}.#{arm.member}")};"
        lines << "    #{local}.#{arm.field} = #{arm.from.call('value', quoted)};"
        lines << "    return #{local};"
      end
      lines << '}'
      lines << "XdrJsonHelper.fail(#{quoted},"
      lines << "    'expects a #{expected} strkey but found " \
               "${XdrJsonHelper.preview(value)}');"
      lines
    },
    imports: [SEP51_STRKEY_IMPORT],
  }
end

# Types the specification renders as something other than their XDR shape, keyed
# by the public generated class name. Consulted before the shape-derived body.
SEP51_TYPE_RENDERERS = {
  'XdrInt128Parts' => sep51_parts_renderer(
    [%w[hi int64], %w[lo uint64]], signed: true
  ),
  'XdrUInt128Parts' => sep51_parts_renderer(
    [%w[hi uint64], %w[lo uint64]], signed: false
  ),
  'XdrInt256Parts' => sep51_parts_renderer(
    [%w[hiHi int64], %w[hiLo uint64], %w[loHi uint64], %w[loLo uint64]], signed: true
  ),
  'XdrUInt256Parts' => sep51_parts_renderer(
    [%w[hiHi uint64], %w[hiLo uint64], %w[loHi uint64], %w[loLo uint64]], signed: false
  ),

  # An account's public key renders as a G-strkey. AccountID and NodeID are
  # typedefs of this union and delegate to it, so neither carries a rendering of
  # its own.
  'XdrPublicKey' => sep51_strkey_union_renderer(
    'XdrPublicKeyType',
    [
      sep51_strkey_arm(
        member: 'PUBLIC_KEY_TYPE_ED25519', field: 'ed25519', prefix: 'G',
        codec: 'StellarAccountId', wrapper: 'XdrUint256', payload: 'uint256'
      ),
    ]
  ),

  # A muxed account renders as the strkey of whichever arm it carries: the bare
  # account for the unmuxed arm, and the M-strkey the med25519 arm renders
  # itself as for the other.
  'XdrMuxedAccount' => sep51_strkey_union_renderer(
    'XdrCryptoKeyType',
    [
      sep51_strkey_arm(
        member: 'KEY_TYPE_ED25519', field: 'ed25519', prefix: 'G',
        codec: 'StellarAccountId', wrapper: 'XdrUint256', payload: 'uint256'
      ),
      sep51_delegating_arm(
        member: 'KEY_TYPE_MUXED_ED25519', field: 'med25519', prefix: 'M',
        type: 'XdrMuxedAccountMed25519'
      ),
    ]
  ),

  # A contract address renders as the strkey of whichever kind of account,
  # contract, balance or pool it names.
  'XdrSCAddress' => sep51_strkey_union_renderer(
    'XdrSCAddressType',
    [
      sep51_delegating_arm(
        member: 'SC_ADDRESS_TYPE_ACCOUNT', field: 'accountId', prefix: 'G',
        type: 'XdrAccountID'
      ),
      sep51_typedef_arm(
        member: 'SC_ADDRESS_TYPE_CONTRACT', field: 'contractId', prefix: 'C',
        typedef: 'XdrContractID'
      ),
      sep51_delegating_arm(
        member: 'SC_ADDRESS_TYPE_MUXED_ACCOUNT', field: 'muxedAccount', prefix: 'M',
        type: 'XdrMuxedAccountMed25519'
      ),
      sep51_delegating_arm(
        member: 'SC_ADDRESS_TYPE_CLAIMABLE_BALANCE', field: 'claimableBalanceId',
        prefix: 'B', type: 'XdrClaimableBalanceID'
      ),
      sep51_typedef_arm(
        member: 'SC_ADDRESS_TYPE_LIQUIDITY_POOL', field: 'liquidityPoolId', prefix: 'L',
        typedef: 'XdrPoolID'
      ),
    ]
  ),

  # A signer renders as the strkey of the kind of key it holds. The three
  # 32-byte arms differ only by codec; the signed-payload arm renders itself.
  'XdrSignerKey' => sep51_strkey_union_renderer(
    'XdrSignerKeyType',
    [
      sep51_strkey_arm(
        member: 'SIGNER_KEY_TYPE_ED25519', field: 'ed25519', prefix: 'G',
        codec: 'StellarAccountId', wrapper: 'XdrUint256', payload: 'uint256'
      ),
      sep51_strkey_arm(
        member: 'SIGNER_KEY_TYPE_PRE_AUTH_TX', field: 'preAuthTx', prefix: 'T',
        codec: 'PreAuthTx', wrapper: 'XdrUint256', payload: 'uint256'
      ),
      sep51_strkey_arm(
        member: 'SIGNER_KEY_TYPE_HASH_X', field: 'hashX', prefix: 'X',
        codec: 'Sha256Hash', wrapper: 'XdrUint256', payload: 'uint256'
      ),
      sep51_delegating_arm(
        member: 'SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD', field: 'signedPayload',
        prefix: 'P', type: 'XdrSignedPayload'
      ),
    ]
  ),

  # A muxed account renders as an M-strkey, whose payload carries the key before
  # the subaccount id -- the reverse of the order the two are declared in. The
  # XDR codec is what reorders them, so the packing is stated once, as the order
  # the two fields are written and read in.
  'XdrMuxedAccountMed25519' => {
    to: lambda { |_public_name|
      [
        'final XdrDataOutputStream stream = XdrDataOutputStream();',
        'XdrUint256.encode(stream, _ed25519);',
        'XdrUint64.encode(stream, _id);',
        'return StrKey.encodeStellarMuxedAccountId(' \
          'Uint8List.fromList(stream.bytes));',
      ]
    },
    from: lambda { |context|
      decode = sep51_strkey_from('StrKey.decodeStellarMuxedAccountId', 'value',
                                 "'#{context[:public_name]}'", 'null',
                                 length: SEP51_STRKEY_MUXED_BYTES)
      [
        "final XdrDataInputStream stream = XdrDataInputStream(#{decode});",
        'final XdrUint256 ed25519 = XdrUint256.decode(stream);',
        'final XdrUint64 id = XdrUint64.decode(stream);',
        "return #{context[:build].call('id, ed25519')};",
      ]
    },
    imports: [SEP51_STRKEY_IMPORT],
  },

  # A signed payload renders as a P-strkey, whose payload region is the XDR
  # encoding of the two fields. An empty payload has no rendering: the strkey
  # the region would produce is one no reader in the ecosystem accepts, so it is
  # refused here rather than emitted for someone else to reject.
  'XdrSignedPayload' => {
    to: lambda { |public_name|
      [
        'XdrJsonHelper.checkSignedPayloadLength(_payload.dataValue.length,',
        "    type: '#{public_name}');",
        'final XdrDataOutputStream stream = XdrDataOutputStream();',
        'XdrUint256.encode(stream, _ed25519);',
        'XdrDataValue.encode(stream, _payload);',
        'return StrKey.encodeCheck(',
        '    VersionByte.SIGNED_PAYLOAD, Uint8List.fromList(stream.bytes));',
      ]
    },
    from: lambda { |context|
      quoted = "'#{context[:public_name]}'"
      [
        'final Uint8List region = XdrJsonHelper.readStrKey(value,',
        "    type: #{quoted},",
        '    key: null,',
        '    decode: (String strKey) =>',
        '        StrKey.decodeCheck(VersionByte.SIGNED_PAYLOAD, strKey));',
        'final (Uint8List ed25519, Uint8List payload) =',
        "    XdrJsonHelper.readSignedPayloadRegion(region, type: #{quoted});",
        "return #{context[:build].call(
          'XdrUint256(ed25519), XdrDataValue(payload)'
        )};",
      ]
    },
    imports: [SEP51_STRKEY_IMPORT],
  },

  # An asset code renders as the code its arm carries, with no envelope around
  # it, so the rendered width is the only thing that names the arm. The two
  # widths cannot overlap: a four-byte code renders trimmed to at most four
  # bytes, and a twelve-byte one is padded back up to at least five.
  'XdrAllowTrustOpAsset' => {
    to: lambda { |public_name|
      quoted = "'#{public_name}'"
      code4 = SEP51_TYPEDEF_RENDERERS.fetch('XdrAssetCode4')
      code12 = SEP51_TYPEDEF_RENDERERS.fetch('XdrAssetCode12')
      [
        'switch (discriminant) {',
        '  case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:',
        "    return #{code4[:to].call('_assetCode4!', quoted, 'null')};",
        '  case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:',
        "    return #{code12[:to].call('_assetCode12!', quoted, 'null')};",
        '}',
        "XdrJsonHelper.fail(#{quoted},",
        "    'holds the unknown discriminant ${discriminant.value}');",
      ]
    },
    from: lambda { |context|
      quoted = "'#{context[:public_name]}'"
      code4 = SEP51_TYPEDEF_RENDERERS.fetch('XdrAssetCode4')
      code12 = SEP51_TYPEDEF_RENDERERS.fetch('XdrAssetCode12')
      [
        '// The width is read before the code so that the arm is chosen by the',
        '// same measure the writer rendered it to. Reading it through the arm',
        '// readers below would need the arm already known.',
        'final int width = XdrJsonHelper.readEscapedBytes(value,',
        "        type: #{quoted}, maxLength: #{SEP51_ASSET_CODE12_BYTES})",
        '    .length;',
        "if (width <= #{SEP51_ASSET_CODE4_BYTES}) {",
        "  final #{context[:result_type]} arm0 = #{context[:build].call(
          'XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4'
        )};",
        "  arm0.assetCode4 = #{code4[:from].call('value', quoted, 'null')};",
        '  return arm0;',
        '}',
        "final #{context[:result_type]} arm1 = #{context[:build].call(
          'XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12'
        )};",
        "arm1.assetCode12 = #{code12[:from].call('value', quoted, 'null')};",
        'return arm1;',
      ]
    },
    imports: [],
  },

  # A claimable balance identifier renders as a B-strkey, whose payload is the
  # discriminant tag followed by the hash. The tag is part of the value rather
  # than of the envelope, so the reader takes the arm from it.
  'XdrClaimableBalanceID' => {
    to: lambda { |public_name|
      [
        'switch (discriminant) {',
        '  case XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0:',
        '    return StrKey.encodeClaimableBalanceId(',
        '        Uint8List.fromList(<int>[discriminant.value, ..._v0!.hash]));',
        '}',
        "XdrJsonHelper.fail('#{public_name}',",
        "    'holds the unknown discriminant ${discriminant.value}');",
      ]
    },
    from: lambda { |context|
      quoted = "'#{context[:public_name]}'"
      decode = sep51_strkey_from('StrKey.decodeClaimableBalanceId', 'value', quoted,
                                 'null', length: SEP51_STRKEY_BALANCE_BYTES)
      [
        "final Uint8List bytes = #{decode};",
        'if (bytes[0] !=',
        '    XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0.value) {',
        "  XdrJsonHelper.fail(#{quoted},",
        "      'carries the unknown discriminant ${bytes[0]}');",
        '}',
        "final #{context[:result_type]} decoded = #{context[:build].call(
          'XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0'
        )};",
        'decoded.v0 = XdrHash(Uint8List.sublistView(bytes, 1));',
        'return decoded;',
      ]
    },
    imports: [SEP51_STRKEY_IMPORT],
  },
}.freeze
