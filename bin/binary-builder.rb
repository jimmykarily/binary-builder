#!/usr/bin/env ruby

require 'bundler'
require 'optparse'
require_relative '../lib/yaml_presenter'
Dir['recipe/*.rb'].each { |f| require File.expand_path(f) }

options = {}
optparser = OptionParser.new do |opts|
  opts.banner = "USAGE: binary-builder [options] (A checksum method is required)"

  opts.on("-nNAME","--name=NAME", "Name of the binary e.g. nginx") do |n|
    options[:name] = n
  end
  opts.on( "-vVERSION","--version=VERSION", "Version of the binary e.g. 1.7.11") do |n|
    options[:version] = n
  end
  opts.on("--sha256=SHA256", "SHA256 of the binary ") do |n|
    options[:sha256] = n
  end
  opts.on("--md5=MD5", "MD5 of the binary ") do |n|
    options[:md5] = n
  end
  opts.on("--gpg-rsa-key-id=RSA_KEY_ID", "RSA Key Id e.g. 10FDE075") do |n|
    options[:gpg] ||= {}
    options[:gpg][:key] = n
  end
  opts.on("--gpg-signature=ASC_KEY", "content of the .asc file") do |n|
    options[:gpg] ||= {}
    options[:gpg][:signature] = n
  end
  opts.on("--source-yaml", "display YAML of the source tarballs and SHA sums") do |n|
    options[:source_yaml] = true
  end
end
optparser.parse!


unless options[:name] && options[:version] && (
    options[:sha256] ||
    options[:md5] ||
    (options[:gpg][:signature] && options[:gpg][:key])
)
  raise optparser.help
end

recipe = case options[:name]
  when "ruby" then RubyRecipe
  when "node" then NodeRecipe
  when "jruby" then JRubyMeal
  when "httpd" then HTTPdMeal
  when "python" then PythonRecipe
  when "php" then PhpMeal
  when "nginx" then NginxRecipe
end

raise "Unsupported #{options[:name]}" unless recipe

recipe = recipe.new(
  options[:name],
  options[:version],
  DetermineChecksum.new(options).to_h
)
Bundler.with_clean_env do
  recipe.cook
  recipe.tar
  if options[:source_yaml]
    puts 'Source YAML:'
    puts YAMLPresenter.new(recipe).to_yaml
  end
end
