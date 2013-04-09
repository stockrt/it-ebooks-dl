#!/usr/bin/env ruby
# coding: utf-8

# Requires.
require 'selenium-webdriver'
require 'colorize'

# Usage.
abort "#{$0} <initial_book_id> <max_downloads> <download_dir> <webdriver>" if ARGV.size != 4

# Defines.
initial_book_id = ARGV[0].to_i
max_downloads = ARGV[1].to_i
download_dir = File.expand_path(ARGV[2])
webdriver = ARGV[3]

# Check.
abort "Download dir not found: #{download_dir}" unless File.directory?(download_dir)

# Webdriver.
case webdriver
when 'firefox'
  # Init Firefox.
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['browser.download.dir'] = download_dir
  profile['browser.download.folderList'] = 2
  profile['browser.helperApps.neverAsk.saveToDisk'] = 'application/pdf'
  $driver = Selenium::WebDriver.for :firefox, :profile => profile
when 'chrome'
  # Init Chrome.
  ENV['PATH'] += ':chromedriver'
  profile = Selenium::WebDriver::Chrome::Profile.new
  profile['download.default_directory'] = download_dir
  profile['download.prompt_for_download'] = false
  $driver = Selenium::WebDriver.for :chrome, :profile => profile
else
  abort "Invalid webdriver: #{webdriver}"
end

# Parse and download.
def process_book(id, download_counter, max_downloads)
  puts "* (#{download_counter}/#{max_downloads}) Processing book_id: #{id}".light_blue

  $driver.navigate.to("http://www.it-ebooks.info/book/#{id}/")
  element = $driver.find_element(:id, 'dl')
  element.click
end

# Loop.
download_counter = 1
while download_counter <= max_downloads do
  process_book(initial_book_id, download_counter, max_downloads)
  initial_book_id += 1
  download_counter += 1
end

# Tear down.
$driver.quit

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
