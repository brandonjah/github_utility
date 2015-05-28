#!/usr/bin/env ruby
require_relative "../lib/application"
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
begin
  ActiveGithub::Application.new(ARGV).run
rescue Errno::ENOENT => err
  abort "active_github: #{err.message}"
end