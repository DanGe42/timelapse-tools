#!/usr/bin/env ruby

require 'pathname'
require 'time'

require 'exif'
require 'mini_magick'

ImageSize = Struct.new(:height, :width, keyword_init: true)

class ExifDataStrict
  attr_reader :exif_data

  def initialize(exif_data)
    @exif_data = exif_data
  end

  # Dynamically allow bang versions of Exif::Data methods. The bang versions
  # strictly enforce that the EXIF data is non-nil.
  def method_missing(method_sym)
    if method_sym.to_s.end_with?('!')
      actual_method = method_sym.to_s.chomp('!').to_sym
      not_nil!(@exif_data.public_send(actual_method), msg: "#{actual_method} is nil")
    else
      @exif_data.public_send(method_sym)
    end
  end

  private

  def not_nil!(a, msg: "value must be non-nil")
    return a unless a.nil?
    raise msg
  end
end

def parse_exif_datetime(exif_datetime)
  Time.strptime(exif_datetime, '%Y:%m:%d %H:%M:%S')
rescue ArgumentError
  raise "Could not parse Date/Time found: #{exif_datetime}"
end

def format_as_time(datetime)
  datetime.strftime('%l:%M:%S %p')
end

def image_dimensions(exif_data)
  ImageSize.new(
    width: exif_data.pixel_x_dimension!,
    height: exif_data.pixel_y_dimension!
  )
end

def signed_number(number)
  # https://stackoverflow.com/a/20539325
  sign = "++-"[number <=> 0]
  "#{sign}#{number}"
end

def offset_string(origin:, x_offset:, y_offset:)
  "#{origin}#{signed_number x_offset}#{signed_number y_offset}"
end

# path: Pathname object
def try_mkdir(path)
  return if path.directory?

  raise "Path #{path} exists but is not a directory" if path.exist?
  path.mkdir
end

def _main(image_path, output_directory)
  output_filename = image_path.basename
  STDERR.puts output_filename

  begin
    image_file = File.open(image_path)
    try_mkdir(output_directory)

    image_exif = ExifDataStrict.new(Exif::Data.new(image_file))
    image_size = image_dimensions(image_exif)
    time_string = format_as_time(parse_exif_datetime(image_exif.date_time_original!))

    MiniMagick::Tool::Convert.new do |cli|
      cli << image_path

      cli.virtual_pixel('mirror')

      # These CLI flags were all taken from the LR Mogrify plugin. It's possible
      # that these can be better tuned (and customizable).
      cli.font('/System/Library/Fonts/Monaco.dfont')
        .undercolor('rgba(0, 0, 0, 0.0)')
        .gravity('SouthWest')
        .fill('rgba(92.86%, 94.04%, 94.01%, 1.00)')
        .density(72)
        .pointsize(108)
        .annotate(offset_string(
          origin: "0x0",
          x_offset: image_size.width / 100 * 2,
          y_offset: image_size.height / 100 * 3
          ), time_string)

      cli.density(240)
        .type("TrueColor")
        .quality(95)

      cli << output_directory + output_filename
    end
  rescue
    STDERR.puts "Unable to process #{image_path}"
    raise
  end
end

def main(args)
  unless args.size == 2
    abort "Usage: #{$0} image output-directory"
  end

  _main(Pathname.new(ARGV[0]), Pathname.new(ARGV[1]))
end

if __FILE__ == $0
  main(ARGV)
end
