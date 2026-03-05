require 'fileutils'
require 'tmpdir'
require 'xdrgen'
require_relative '../generator/generator'

SNAPSHOT_DIR = File.expand_path("snapshots", __dir__)

Dir.chdir(File.expand_path("../../..", __dir__))
output = Dir.mktmpdir("xdr_snapshots_")

Xdrgen::Compilation.new(
  Dir.glob("xdr/*.x"),
  output_dir: output + "/",
  generator: Generator,
  namespace: "stellar",
).compile

FileUtils.mkdir_p(SNAPSHOT_DIR)
Dir.glob(File.join(SNAPSHOT_DIR, "*.dart")).each { |f| File.delete(f) }

count = 0
%w[
  xdr_data_entry.dart
  xdr_time_bounds.dart
  xdr_price.dart
  xdr_asset.dart
  xdr_memo.dart
  xdr_hash.dart
  xdr_asset_type.dart
  xdr_contract_executable_base.dart
  xdr_contract_cost_params.dart
].each do |f|
  src = File.join(output, f)
  if File.exist?(src)
    FileUtils.cp(src, SNAPSHOT_DIR)
    count += 1
  else
    warn "Warning: #{f} not found in generated output"
  end
end

FileUtils.rm_rf(output)
puts "Updated #{count} snapshots in #{SNAPSHOT_DIR}"
