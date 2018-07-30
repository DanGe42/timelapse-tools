#!/usr/bin/env ruby

require 'pathname'

input_dir = ARGV[0]
prefix = ARGV[1]
output_dir = ARGV[2]

if !input_dir || !prefix || !output_dir
  abort "Usage: renumber_files.rb directory prefix out_directory"
end

input_dir = Pathname.new(input_dir)
output_dir = Pathname.new(output_dir)

files = Dir.glob(input_dir + "*.JPG")
digits = files.size.to_s.size

files.each_with_index do |file, index|
  padded_index = "#{index}".rjust(digits, '0')
  destination = output_dir + "#{prefix}#{padded_index}.JPG"
  File.symlink(file, destination)
end
