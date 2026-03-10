require 'xdrgen'
require_relative 'generator/generator'

puts "Generating Dart XDR classes..."

Dir.chdir("../..")

Xdrgen::Compilation.new(
  Dir.glob("xdr/*.x"),
  output_dir: "lib/src/xdr/",
  generator: Generator,
  namespace: "stellar",
).compile

puts "Done!"
