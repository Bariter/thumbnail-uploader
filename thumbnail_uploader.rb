#!/usr/bin/env ruby

require 'net/http'
require 'securerandom'

@host = 'localhost'
@port = '3000'.to_i

@path = '/thumbnails'

@uri = URI("http://#{@host}:#{@port}#{@path}")

@BOUNDARY = SecureRandom.hex(8).freeze

class UploadImage
  attr_reader :file_path
  def initialize(file_path)
    @file_path = file_path
  end

  def file_type
    return File.extname(@file_path)
  end

  def to_binary
    return File.read(@file_path)
  end

  def url_prefix
    case File.basename(@file_path, '.*')
    when "xvideos"
      "xvideos"
    end
  end
end

# ref: http://stackoverflow.com/questions/913626/what-should-a-multipart-http-r
#   equest-with-multiple-files-look-like
# ref: http://www.rubyinside.com/nethttp-cheat-sheet-2940.html
def create_multipart_data(path_to_image)
  upload_image = UploadImage.new(path_to_image)
  
  body_data = []
  body_data << "--#{@BOUNDARY}\r\n"
  body_data << "Content-Disposition: form-data; name=\"url_prefix\"\r\n"
  body_data << "Content-type: text/plain\r\n"
  body_data << "\r\n"
  body_data << "#{upload_image.url_prefix}"
  body_data << "\r\n"

  body_data << "--#{@BOUNDARY}\r\n"
  body_data << "Content-Disposition: form-data; name=\"image\"\r\n"
  body_data << "Content-type: image/#{upload_image.file_type}\r\n"
  body_data << "\r\n"
  body_data << upload_image.to_binary
  body_data << "\r\n--#{@BOUNDARY}--\r\n"

  return body_data.join
end

def post(path_to_image)
  req = Net::HTTP::Post.new(@uri)
  req.body = create_multipart_data(path_to_image)
  req.content_type = "multipart/form-data, boundary=#{@BOUNDARY}"
  response = Net::HTTP.new(@host, @port).start {|http| http.request(req) }
  puts "Response #{response.code} #{response.message}: #{response.body}"
end

if ARGV.nil? || ARGV.length != 1
  abort "Usage: ./image_uplaoder.rb <path_to_image>"
end

post ARGV[0]

puts "\r\nDONE!!"
