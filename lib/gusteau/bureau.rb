require 'etc'
require 'erb'
require 'yaml'
require 'json'
require 'fileutils'

module Gusteau
  class Bureau
    def initialize(name)
      template_path = File.expand_path('../../../template', __FILE__)

      @login   = Etc.getlogin
      @ssh_key = File.read(File.expand_path '~/.ssh/id_rsa.pub').chomp rescue 'Your SSH key'

      abort "Directory #{name} already exists" if Dir.exists?(name)

      FileUtils.cp_r(template_path, name)

      File.open(File.join(name, 'nodes', 'example.yml'), 'w+') do |f|
        read_erb(File.join(template_path, 'nodes', 'example.yml.erb')).tap do |node|
          f.write node
          f.close
        end

        FileUtils.rm(File.join(name, 'nodes', 'example.yml.erb'))
      end

      File.open(File.join(name, 'data_bags', 'users', "#{@login}.json"), 'w+') do |f|
        read_erb_json(File.join(template_path, 'data_bags', 'users', 'user.json.erb')).tap do |user|
          f.write JSON::pretty_generate user
          f.close
        end

        FileUtils.rm(File.join(name, 'data_bags', 'users', 'user.json.erb'))
      end

      puts "Created bureau '#{name}'"
      Dir.chdir(name) do
        puts   'Installing gem dependencies'
        system 'bundle'

        puts   'Installing cookbooks'
        system 'librarian-chef install'
      end
    end

    private

    def read_erb(path)
      ERB.new(File.read(path)).result binding
    end

    def read_erb_json(path)
      JSON::parse(read_erb path)
    end
  end
end
