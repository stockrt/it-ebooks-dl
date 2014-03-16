#!/usr/bin/env ruby
# coding: utf-8

##############
## REQUIRES ##
##############

require 'colorize'
require 'net/http'
require 'mechanize'
require 'ruby-progressbar'

##########
## MAIN ##
##########

def main
  # Usage.
  abort "#{$0} <initial_book_id> <max_downloads> <download_dir>" if ARGV.size != 3

  # Params.
  initial_book_id = ARGV[0].to_i
  max_downloads = ARGV[1].to_i
  download_dir = File.expand_path(ARGV[2])

  # Check.
  abort "Download dir not found: #{download_dir}" unless File.directory?(download_dir)

  # Loop.
  download_counter = 1
  while download_counter <= max_downloads do
    process_book(initial_book_id, download_counter, max_downloads, download_dir)
    initial_book_id += 1
    download_counter += 1
  end
end

def valid_encode(str)
  return str if str.nil?
  return str.chars.select { |char| char.valid_encoding? }.join
end

# Parse and download.
def process_book(id, download_counter, max_downloads, download_dir)
  domain = 'www.it-ebooks.info'
  ua = 'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:19.0) Gecko/20100101 Firefox/19.0'

  puts "* (#{download_counter}/#{max_downloads}) Processing book_id: #{id}".light_blue

  # Agent.
  a = Mechanize.new do |agent|
    agent.user_agent = ua
  end

  # Book page.
  a.get("http://#{domain}/book/#{id}/") do |page|
    download_link = page.link_with(:id => 'dl')
    if download_link.nil?
      download_link = page.link_with(:href => /filepi/)
    end

    if download_link.nil?
      puts "- Download link not found (id: #{id})".light_red
      return
    end

    uri = URI(download_link.href)
    author = valid_encode(page.parser.xpath('//td/b[@itemprop="author"]').children.to_s).strip
    author = author.split(',')[0..2].join(' + ').strip
    title = valid_encode(page.parser.xpath('//h1').children.to_s).strip
    publisher = valid_encode(page.parser.xpath('//td/b/a[@itemprop="publisher"]').children.to_s).strip
    date = valid_encode(page.parser.xpath('//td/b[@itemprop="datePublished"]').children.to_s).strip
    pages = valid_encode(page.parser.xpath('//td/b[@itemprop="numberOfPages"]').children.to_s).strip
    lang = valid_encode(page.parser.xpath('//td/b[@itemprop="inLanguage"]').children.to_s).strip.downcase
    isbn = valid_encode(page.parser.xpath('//td/b[@itemprop="isbn"]').children.to_s).strip
    format = valid_encode(page.parser.xpath('//td/b[@itemprop="bookFormat"]').children.to_s).strip.downcase
    size = valid_encode(page.parser.xpath('//tr[8]/td[2]/b').children.to_s).strip

    filename = "#{author} - #{title} - #{publisher} - #{date} - #{pages}p - #{lang} - ISBN #{isbn}.#{format}"
    filename.gsub!(/ +/, '_')
    filename.gsub!(/\/+/, '_')
    filename.gsub!(/(-|_| )\.#{format}/, ".#{format}")
    filename.chomp!

    filename_path = "#{download_dir}/#{filename}"
    filename_part_path = "#{filename_path}.part"

    if File.exist?(filename_path)
      puts "- Already downloaded (id: #{id} / #{size}): #{filename}".light_yellow
    else
      if File.exist?(filename_part_path)
        puts "+ Resuming download (id: #{id} / #{size}): #{filename}".light_green
        filename_part_size = File.stat(filename_part_path).size
        request_headers = {'User-Agent' => ua, 'Referer' => "http://#{domain}", 'Range' => "bytes=#{filename_part_size}-"}
      else
        puts "+ Downloading (id: #{id} / #{size}): #{filename}".light_green
        filename_part_size = 0
        request_headers = {'User-Agent' => ua, 'Referer' => "http://#{domain}"}
      end

      # Book download.
      counter = filename_part_size
      if uri.host.nil?
        download_domain = domain
      else
        download_domain = uri.host
      end

      Net::HTTP.start(download_domain) do |http|
        # No Range here, we want to know the total Content-Length.
        response = http.request_head(uri.to_s, {'User-Agent' => ua, 'Referer' => "http://#{domain}"})

        pbar = ProgressBar.create(:starting_at  => filename_part_size,
                                  :total        => response['Content-Length'].to_i,
                                  :format       => '%a %B %p%% %c/%C %e')

        File.open(filename_part_path, 'ab') do |file|
          http.request_get(uri.to_s, request_headers) do |response|
            if response.code == 200
              counter = 0
              file.truncate(0)
            end

            response.read_body do |stream|
              file.write stream
              counter += stream.length
              pbar.progress = counter
            end
          end
        end

        File.rename("#{filename_path}.part", filename_path)
      end
    end
  end
end

begin
  main
rescue Interrupt
  puts
  puts 'Exiting.'
  exit 0
end
