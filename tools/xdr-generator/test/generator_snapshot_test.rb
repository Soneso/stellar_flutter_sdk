require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'
require 'stringio'
require_relative '../generator/generator'

class GeneratorSnapshotTest < Minitest::Test
  SNAPSHOT_DIR = File.expand_path("snapshots", __dir__)
  XDR_DIR      = File.expand_path("../../../xdr", __dir__)

  # Generate once for all tests (iOS SDK bug: regenerates per test method)
  @@output_dir = nil
  @@generated = false

  def setup
    unless @@generated
      @@output_dir = Dir.mktmpdir("xdr_gen_test_")
      Dir.chdir(File.expand_path("../../..", __dir__))
      Xdrgen::Compilation.new(
        Dir.glob("xdr/*.x"),
        output_dir: @@output_dir + "/",
        generator: Generator,
        namespace: "stellar",
      ).compile
      @@generated = true
    end
    @output_dir = @@output_dir
  end

  Minitest.after_run { FileUtils.rm_rf(@@output_dir) if @@output_dir }

  # -- Configuration tests --
  def test_generator_loads
    assert defined?(Generator), "Generator class should be defined"
  end

  def test_overrides_loaded
    assert NAME_OVERRIDES.is_a?(Hash)
    assert FIELD_OVERRIDES.is_a?(Hash)
    assert TYPE_OVERRIDES.is_a?(Hash)
  end

  # -- Snapshot tests (9 files) --
  def test_snapshot_data_entry;              assert_snapshot "xdr_data_entry.dart"; end
  def test_snapshot_time_bounds;             assert_snapshot "xdr_time_bounds.dart"; end
  def test_snapshot_price;                   assert_snapshot "xdr_price.dart"; end
  def test_snapshot_asset;                   assert_snapshot "xdr_asset.dart"; end
  def test_snapshot_memo;                    assert_snapshot "xdr_memo.dart"; end
  def test_snapshot_hash;                    assert_snapshot "xdr_hash.dart"; end
  def test_snapshot_asset_type;              assert_snapshot "xdr_asset_type.dart"; end
  def test_snapshot_contract_executable_base; assert_snapshot "xdr_contract_executable_base.dart"; end
  def test_snapshot_contract_cost_params;    assert_snapshot "xdr_contract_cost_params.dart"; end

  # -- Output sanity checks --
  def test_generated_files_count
    count = Dir.glob(File.join(@output_dir, "*.dart")).length
    assert count > 400, "Should generate 400+ files, got #{count}"
  end

  # -- Semantic checks --
  def test_uint32_union_discriminant_uses_uint32_txrep_reader
    top = Xdrgen::Parser.new.parse(<<~XDR)
      typedef unsigned int uint32;
      union TestUnion switch (uint32 v) { case 0: void; };
    XDR
    union = top.definitions.find { |definition| definition.is_a?(AST::Definitions::Union) }
    generator = Generator.new(top, nil)
    disc_info = generator.send(:resolve_discriminant_info, union)
    arms = generator.send(:build_union_arms, union, 'XdrTestUnion', disc_info)
    output = StringIO.new
    generator.send(:render_union_txrep_methods, output, 'XdrTestUnion', disc_info, arms)
    assert_includes output.string,
      "int disc = TxRepHelper.parseUint32(TxRepHelper.getValue(map, '$prefix.v') ?? '0', '$prefix.v');"
  end

  def test_fixed_opaque_fields_emit_exact_length_checks
    hash = File.read(File.join(@output_dir, "xdr_hash.dart"))
    assert_includes hash, "stream.writeFixedOpaque(encodedHash.hash, 32);"
    assert_includes hash, "XdrJsonHelper.hex(_hash, type: 'XdrHash', expectedLength: 32)"
    assert_includes hash, "TxRepHelper.checkBytesExactLength(_hash, 32, prefix)"
    assert_includes hash, "TxRepHelper.checkBytesExactLength(TxRepHelper.hexToBytes(raw), 32, prefix)"

    seed = File.read(File.join(@output_dir, "xdr_short_hash_seed.dart"))
    assert_includes seed, "stream.writeFixedOpaque(encodedShortHashSeed.seed, 16);"
    assert_includes seed, "XdrJsonHelper.hex(_seed, type: 'XdrShortHashSeed', key: 'seed', expectedLength: 16)"

    ip = File.read(File.join(@output_dir, "xdr_peer_address_ip.dart"))
    assert_includes ip, "stream.writeFixedOpaque(encodedPeerAddressIp._ipv4!, 4);"
    assert_includes ip, "stream.writeFixedOpaque(encodedPeerAddressIp._ipv6!, 16);"
    assert_includes ip, "XdrJsonHelper.hex(_ipv4!, type: 'XdrPeerAddressIp', key: 'i_pv4', expectedLength: 4)"
    assert_includes ip, "XdrJsonHelper.hex(_ipv6!, type: 'XdrPeerAddressIp', key: 'i_pv6', expectedLength: 16)"
  end

  def test_variable_opaque_fields_keep_variable_length_codecs
    data_val = File.read(File.join(@output_dir, "xdr_data_value.dart"))
    assert_includes data_val, "stream.writeBoundedLength(dataValueSize, 64);"
    assert_includes data_val, "stream.write(encodedDataValue.dataValue);"
    refute_includes data_val, "writeFixedOpaque"
    assert_includes data_val, "XdrJsonHelper.hex(_dataValue, type: 'XdrDataValue', maxLength: 64)"
    refute_includes data_val, "expectedLength"
    assert_includes data_val, "TxRepHelper.bytesToHex(_dataValue)"
    refute_includes data_val, "checkBytesExactLength"

    contract_code = File.read(File.join(@output_dir, "xdr_contract_code_entry.dart"))
    assert_includes contract_code, "stream.write(encodedContractCodeEntry.code);"
    refute_includes contract_code, "writeFixedOpaque(encodedContractCodeEntry.code"
  end

  def test_asset_code_fields_emit_padding_writers_and_bounded_readers
    a4 = File.read(File.join(@output_dir, "xdr_asset_alpha_num4.dart"))
    assert_includes a4, "stream.writeAssetCode(encodedAssetAlphaNum4.assetCode, 4);"
    assert_includes a4, "XdrJsonHelper.assetCode4(_assetCode, type: 'XdrAssetAlphaNum4', key: 'asset_code')"
    assert_includes a4, "TxRepHelper.padAssetCode(_assetCode, 4, '$prefix.assetCode')"
    assert_includes a4, "TxRepHelper.checkBytesMaxLength(TxRepHelper.hexToBytes(TxRepHelper.getValue(map, '$prefix.assetCode') ?? ''), 4, '$prefix.assetCode')"

    a12 = File.read(File.join(@output_dir, "xdr_asset_alpha_num12.dart"))
    assert_includes a12, "stream.writeAssetCode(encodedAssetAlphaNum12.assetCode, 12);"
    assert_includes a12, "XdrJsonHelper.assetCode12(_assetCode, type: 'XdrAssetAlphaNum12', key: 'asset_code')"
    assert_includes a12, "TxRepHelper.padAssetCode(_assetCode, 12, '$prefix.assetCode')"
    assert_includes a12, "TxRepHelper.checkBytesMaxLength(TxRepHelper.hexToBytes(TxRepHelper.getValue(map, '$prefix.assetCode') ?? ''), 12, '$prefix.assetCode')"

    allow = File.read(File.join(@output_dir, "xdr_allow_trust_op_asset.dart"))
    assert_includes allow, "stream.writeAssetCode(encodedAllowTrustOpAsset._assetCode4!, 4);"
    assert_includes allow, "stream.writeAssetCode(encodedAllowTrustOpAsset._assetCode12!, 12);"
    assert_includes allow, "TxRepHelper.padAssetCode(_assetCode4!, 4, '$prefix.assetCode4')"
    assert_includes allow, "TxRepHelper.padAssetCode(_assetCode12!, 12, '$prefix.assetCode12')"
    assert_includes allow, "TxRepHelper.checkBytesMaxLength(TxRepHelper.hexToBytes(TxRepHelper.getValue(map, '$prefix.assetCode4') ?? ''), 4, '$prefix.assetCode4')"
    assert_includes allow, "TxRepHelper.checkBytesMaxLength(TxRepHelper.hexToBytes(TxRepHelper.getValue(map, '$prefix.assetCode12') ?? ''), 12, '$prefix.assetCode12')"
  end

  def test_fixed_opaque_typedef_chain_and_constant_bound_resolution
    top = Xdrgen::Parser.new.parse(<<~XDR)
      const KEY_LEN = 16;
      typedef opaque RawKey[KEY_LEN];
      typedef RawKey ChainedKey;
      typedef opaque AssetCode4[4];
      typedef AssetCode4 ChainedAssetCode4;
      struct TestFixed {
        opaque inlineKey[KEY_LEN];
        AssetCode4* optCode;
        ChainedKey chained;
      };
    XDR
    generator = Generator.new(top, nil)
    struct = top.definitions.find { |d| d.is_a?(AST::Definitions::Struct) }
    chained_member = struct.members.find { |m| m.name.to_s == 'chained' }
    assert_equal '16', generator.send(:fixed_opaque_typedef_size, chained_member.declaration.type)

    chained_code_td = top.definitions.find { |d| d.is_a?(AST::Definitions::Typedef) && d.name.to_s == 'ChainedAssetCode4' }
    assert generator.send(:asset_code_typedef?, chained_code_td.declaration.type)

    fields = struct.members.map do |m|
      type_str = generator.send(:dart_type_string, m.declaration, m)
      fos = type_str.delete_suffix('?') == 'Uint8List' && m.declaration.respond_to?(:type) ?
              generator.send(:fixed_opaque_typedef_size, m.declaration.type) : nil
      {
        name: m.name.to_s,
        type: type_str,
        member: m,
        decl: m.declaration,
        fixed_opaque_size: fos,
        asset_code: fos ? generator.send(:asset_code_typedef?, m.declaration.type) : false,
        type_overridden: false,
      }
    end
    out = StringIO.new
    generator.send(:render_struct_encode, out, 'XdrTestFixed', fields)
    assert_includes out.string, "stream.writeFixedOpaque(encodedTestFixed.inlineKey, 16);"
    assert_includes out.string, "stream.writeAssetCode(encodedTestFixed.optCode!, 4);"

    txrep = StringIO.new
    generator.send(:render_struct_txrep_methods, txrep, 'XdrTestFixed', fields)
    assert_includes txrep.string, "TxRepHelper.checkBytesExactLength(_inlineKey, 16, '$prefix.inlineKey')"
    assert_includes txrep.string, "TxRepHelper.checkBytesExactLength(TxRepHelper.hexToBytes(TxRepHelper.getValue(map, '$prefix.inlineKey') ?? ''), 16, '$prefix.inlineKey')"
    assert_includes txrep.string, "String optCodeHex = TxRepHelper.bytesToHex(TxRepHelper.padAssetCode(_optCode!, 4, '$prefix.optCode'));"
    assert_includes txrep.string, "TxRepHelper.checkBytesMaxLength(TxRepHelper.hexToBytes(TxRepHelper.getValue(map, '$prefix.optCode') ?? ''), 4, '$prefix.optCode')"
  end

  def test_recursive_decoders_match_type_cycles
    sources = Dir.glob(File.join(@output_dir, '*.dart')).to_h do |path|
      source = File.read(path)
      type = source[/^class (\w+)/, 1].delete_suffix('Base')
      decoders = source.scan(/^  static [^\n]* (?:decode|decodeAs)(?:<[^\n]*)?\([\s\S]*?^  \}/).join
      [type, decoders]
    end
    graph = sources.transform_values { |body| body.scan(/\b(Xdr\w+)\.decode\(/).flatten.map { |t| t.delete_suffix('Base') }.uniq }
    recursive = graph.keys.select do |origin|
      pending = graph.fetch(origin).dup
      visited = Set.new
      until pending.empty?
        type = pending.pop
        break if type == origin
        pending.concat(graph.fetch(type, [])) if visited.add?(type)
      end
      type == origin
    end.to_set
    assert_equal RECURSIVE_DECODE_TYPES, recursive
    sources.each do |type, body|
      expected = recursive.include?(type) ? 1 : 0
      assert_equal expected, body.scan('stream.enterRecursiveDecode();').length, type
      assert_equal expected, body.scan('stream.exitRecursiveDecode();').length, type
    end
  end

  def test_generated_marker_present
    content = File.read(File.join(@output_dir, "xdr_price.dart"))
    assert_includes content, "automatically generated by xdrgen"
  end

  def test_typedef_resolution_in_structs
    content = File.read(File.join(@output_dir, "xdr_data_entry.dart"))
    assert_includes content, "XdrAccountID"
  end

  def test_base_wrapper_types_generate_base_file
    assert File.exist?(File.join(@output_dir, "xdr_contract_executable_base.dart")),
      "BASE_WRAPPER_TYPES should generate _base.dart files"
  end

  def test_field_overrides_applied
    content = File.read(File.join(@output_dir, "xdr_data_entry.dart"))
    assert_includes content, "dataName"
  end

  private

  def assert_snapshot(filename)
    generated = File.join(@output_dir, filename)
    snapshot  = File.join(SNAPSHOT_DIR, filename)
    assert File.exist?(generated), "Generated file #{filename} should exist"
    assert File.exist?(snapshot), "Snapshot file #{filename} should exist — run 'make xdr-generator-update-snapshots'"
    assert_equal File.read(snapshot), File.read(generated),
      "Generated #{filename} does not match snapshot — run 'make xdr-generator-update-snapshots' if change is intentional"
  end
end
