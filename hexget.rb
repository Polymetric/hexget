#!/usr/bin/env ruby
require 'httparty'
require 'git'
require 'tty-spinner'

PACKAGE_NAME = ARGV[0]
@base_dir = "/tmp/hexget"

spinner = TTY::Spinner.new("[:spinner] Creating base dirs in #{@base_dir}", format: :dots, interval: 10)
spinner.start
FileUtils.mkdir_p @base_dir
Dir.chdir @base_dir
spinner.success

spinner = TTY::Spinner.new("[:spinner] Pulling package data for #{PACKAGE_NAME} from hex.pm", format: :dots, interval: 10)
spinner.start
package_data = HTTParty.get "https://hex.pm/api/packages/#{PACKAGE_NAME}"
spinner.success

release_version = package_data['releases'].first['version']
github_url = "#{package_data['meta']['links'].first[1]}.git"

spinner = TTY::Spinner.new("[:spinner] Cloning repo from #{github_url}", format: :dots, interval: 10)
spinner.start
Git.clone(github_url, PACKAGE_NAME, :path => "./#{PACKAGE_NAME}/#{release_version}")
spinner.success

spinner = TTY::Spinner.new("[:spinner] Moving into directory for compile", format: :dots, interval: 10)
spinner.start
FileUtils.mkdir_p "./#{PACKAGE_NAME}/#{release_version}"
Dir.chdir "./#{PACKAGE_NAME}/#{release_version}/#{PACKAGE_NAME}"
spinner.success

# Uncomment if you need to compile things for production.
# ENV['MIX_ENV'] = "production"
# Also please don't use this in production.

spinner = TTY::Spinner.new("[:spinner] Figuring out if we're in Elixir land or Erlang world", format: :dots, interval: 10)
spinner.start
if File.exist?("./rebar.config")
  @type = "rebar"
else
  @type = "mix"
end
spinner.success

spinner = TTY::Spinner.new("[:spinner] Getting dependencies...", format: :dots, interval: 10)
spinner.start
if @type == "rebar"
  `rebar get-deps`
else
  `mix deps.get`
end
spinner.success

spinner = TTY::Spinner.new("[:spinner] Compiling...", format: :dots, interval: 10)
spinner.start
`#{@type} compile`
spinner.success

spinner = TTY::Spinner.new("[:spinner] Moving compiled beams into #{ENV['HOME']}/.mix/beam", format: :dots, interval: 10)
spinner.start
FileUtils.mkdir_p "#{ENV['HOME']}/.mix/beam/#{PACKAGE_NAME}"
if @type == "rebar"
  FileUtils.cp_r("./ebin/.", "#{ENV['HOME']}/.mix/beam")
else
  Dir.foreach("./_build/dev/lib") do |dir|
    next if dir == '.' or dir == '..'
    FileUtils.cp_r("./_build/dev/lib/#{dir}/ebin/.", "#{ENV['HOME']}/.mix/beam")
  end
end
spinner.success

at_exit do
  spinner = TTY::Spinner.new("[:spinner] Removing downloaded git repo", format: :dots, interval: 10)
  spinner.start
  FileUtils.remove_entry_secure("#{@base_dir}/#{PACKAGE_NAME}/#{release_version}")
  spinner.success
end
