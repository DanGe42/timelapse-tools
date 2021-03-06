#!/usr/bin/env ruby
require 'pathname'

input_dir = ARGV[0]
prefix = ARGV[1]
output_dir = ARGV[2]

if !input_dir || !prefix || !output_dir
  abort "Usage: renumber_files.rb directory prefix out_directory"
end

def try_mkdir(path)
  return if path.directory?

  raise "Path #{path} exists but is not a directory" if path.exist?
  path.mkdir
end

input_dir = Pathname.new(input_dir)
output_dir = Pathname.new(output_dir)

try_mkdir(output_dir)

files = Dir.glob(input_dir + "*.JPG")
digits = files.size.to_s.size

files.map { |f| Pathname.new(f) }.each_with_index do |path, index|
  padded_index = "#{index}".rjust(digits, '0')
  destination = output_dir + "#{prefix}#{padded_index}.JPG"
  File.symlink(path.relative_path_from(output_dir), destination)
end
