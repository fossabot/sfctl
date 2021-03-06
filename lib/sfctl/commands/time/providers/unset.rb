require 'pastel'
require 'tty-prompt'
require_relative '../../../command'

module Sfctl
  module Commands
    class Time
      class Providers
        class Unset < Sfctl::Command
          def initialize(options)
            @options = options
            @pastel = Pastel.new(enabled: !@options['no-color'])
          end

          def execute(output: $stdout)
            return unless config_present?(output)

            prompt = ::TTY::Prompt.new
            provider = prompt.select('Unsetting:', PROVIDERS_LIST)

            if config.fetch(:providers, provider).nil?
              output.puts @pastel.yellow("[#{provider}] is already deleted from configuration.")
            elsif prompt.yes?('Do you want to remove the delete the configuration?')
              remove_provider!(provider, output)
            end
          end

          private

          def remove_provider!(provider, output)
            providers = config.fetch(:providers)
            providers.delete(provider)
            config.set(:providers, value: providers)
            save_config!
            output.puts @pastel.green("Configuration for provider [#{provider}] was successfully deleted.")
          end
        end
      end
    end
  end
end
