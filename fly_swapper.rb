#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'yaml'

class FlySwapper
    def execute
        download_versioned_cli unless versioned_cli_exists?
        execute_command_with_args
    end

    def download_versioned_cli
        download_url = "#{target_url}/api/v1/cli?arch=amd64&platform=darwin"
        puts "Downloading fly v#{target_version} from #{download_url}"
        puts "=" * 20
        `wget "#{download_url}" -O #{versioned_cli_path} && chmod +x #{versioned_cli_path}`
    end

    def execute_command_with_args
        system("#{versioned_cli_path} #{ARGV.join(' ')}")
    end

    def versioned_cli_exists?
        target_version && File.exists?(versioned_cli_path)
    end

    def versioned_cli_path
        "/usr/local/bin/fly-#{target_version}"
    end

    def target_version
        info = JSON.parse(Net::HTTP.get(URI("#{target_url}/api/v1/info")))
        info['version']
    end

    def target_url
        fly_config = YAML.load(File.read(File.expand_path('~/.flyrc')))
        raise "Unknown target `#{target}` in ~/.flyrc" if fly_config['targets'][target].nil?
        fly_config['targets'][target]['api']
    end

    def target
        index = ARGV.find_index('-t') || ARGV.find_index('--target')
        ARGV[index + 1]
    end
end

FlySwapper.new.execute