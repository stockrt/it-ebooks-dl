#!/usr/bin/env ruby
# coding: utf-8

# Requires.
require 'mechanize'
require 'colorize'

# Usage.
abort "#{$0} <initial_book_id> <max_downloads> <download_dir>" if ARGV.size != 3

# Defines.
initial_book_id = ARGV[0].to_i
max_downloads = ARGV[1].to_i
download_dir = File.expand_path(ARGV[2])

# Check.
abort "Download dir not found: #{download_dir}" unless File.directory?(download_dir)

# Parse and download.
def process_book(id, download_num, download_dir)
  puts "* (#{download_num}) Processing book_id: #{id}".light_blue

  # Agent.
  a = Mechanize.new do |agent|
    agent.user_agent = 'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:19.0) Gecko/20100101 Firefox/19.0'
  end

  a.get("http://www.it-ebooks.info/book/#{id}/") do |page|
    author = page.parser.xpath('//td/b[@itemprop="author"]').children.to_s
    title = page.parser.xpath('//h1').children.to_s
    publisher = page.parser.xpath('//td/b/a[@itemprop="publisher"]').children.to_s
    date = page.parser.xpath('//td/b[@itemprop="datePublished"]').children.to_s
    pages = page.parser.xpath('//td/b[@itemprop="numberOfPages"]').children.to_s
    lang = page.parser.xpath('//td/b[@itemprop="inLanguage"]').children.to_s.downcase
    isbn = page.parser.xpath('//td/b[@itemprop="isbn"]').children.to_s
    format = page.parser.xpath('//td/b[@itemprop="bookFormat"]').children.to_s.downcase
    size = page.parser.xpath('//tr[8]/td[2]/b').children.to_s

    filename = "#{author} - #{title} - #{publisher} - #{date} - #{pages}p - #{lang} - ISBN #{isbn}.#{format}"
    filename.gsub!(' ', '_')
    filename.delete!('\'')
    filename.chomp!

    filename_path = "#{download_dir}/#{filename}"
    if File.exist?(filename_path)
      puts "- Already downloaded (#{id} / #{size}): #{filename}".light_yellow
    else
      puts "+ Downloading (#{id} / #{size}): #{filename}".light_green
      a.click(page.link_with(:id => 'dl')).save_as(filename_path)
    end
  end
end

# Loop.
download_counter = 1
while download_counter <= max_downloads do
  process_book(initial_book_id, download_counter, download_dir)
  initial_book_id += 1
  download_counter += 1
end

=begin
<tr><td width="150">Publisher:</td><td><b><a href="/publisher/3/" title="O'Reilly Media eBooks" itemprop="publisher">O'Reilly Media</a></b></td></tr>
<tr><td>By:</td><td><b itemprop="author" style="display:none;">Cricket Liu</b><b><a href='/author/327/' title='Cricket Liu'>Cricket Liu</a></b></td></tr>
<tr><td>ISBN:</td><td><b itemprop="isbn">978-1-4493-0519-2</b></td></tr>
<tr><td>Year:</td><td><b itemprop="datePublished">2011</b></td></tr>
<tr><td>Pages:</td><td><b itemprop="numberOfPages">52</b></td></tr>
<tr><td>Language:</td><td><b itemprop="inLanguage">English</b></td></tr>
<tr><td>File size:</td><td><b>0.7 MB</b></td></tr>
<tr><td>File format:</td><td><b itemprop="bookFormat">PDF</b></td></tr>
<tr><td colspan="2"><h4>eBook</h4></td></tr>
<tr><td>Download:</td><td>
<a id="dl" href="/go.php?id=433-1365152009-ccad9a79ffff872d665d5e3b27c9e9ce" rel="nofollow">Free</a>    <script>$("#dl").text("DNS and BIND on IPv6")</script>
=end
