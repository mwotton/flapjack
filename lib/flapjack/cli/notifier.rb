#!/usr/bin/env ruby

require 'ostruct'
require 'optparse'
require 'log4r'
require 'log4r/outputter/syslogoutputter'
require File.join(File.dirname(__FILE__), '..', 'inifile')

module Flapjack
  module Notifier
    class Options
      def self.parse(args)
        options = OpenStruct.new
        opts = OptionParser.new do |opts|
          opts.on('-r', '--recipients FILE', 'recipients file') do |filename|
            options.recipients_filename = filename
          end
          opts.on('-c', '--config FILE', 'config file') do |filename|
            options.config_filename = filename
          end
          opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
          end
        end

        # parse the options
        begin
          opts.parse!(args)
        rescue OptionParser::MissingArgument => e
          # if an --option is missing it's argument
          puts e.message.capitalize + "\n\n"
          puts opts
          exit 1
        end

        # validation of command line arguments
        @errors = []
        # check that recipients file exists
        if options.recipients_filename
          unless File.exists?(options.recipients_filename)
            @errors << "The specified recipients file doesn't exist!"
          end
        else
          @errors << "You need to specify a recipients file with --recipients."
        end
  
        # check that config file exists
        if options.config_filename 
          unless File.exists?(options.config_filename.to_s)
            @errors << "The specified config file doesn't exist!"
          end
        else
          options.config_filename = "/etc/flapjack/flapjack-notifier.conf"
          unless File.exists?(options.config_filename)
            @errors << "The default config file (#{options.config_filename}) doesn't exist."
            @errors << "Please set one up, or specify one with --config."
          end
        end
      

        # if there are errors, print them out and exit
        if @errors.size > 0
          puts "Errors:"
          @errors.each do |error|
            puts "  - #{error}"
          end
          puts
          puts opts
          exit 2
        end
    
        # config loader

        # holder for transport + persistence config
        options.transport   = OpenStruct.new
        options.persistence = OpenStruct.new

        config = Flapjack::Inifile.read(options.config_filename)

        %w(transport persistence).each do |backend|
          options.send("#{backend}=", config[backend].symbolize_keys)
        end

        # base config (config.blah)
        config['notifier'].each_pair do |key, value|
          normalised_key = key.gsub('-', '_')
          values = value.split(/,*\s+/)
          options.send("#{normalised_key}=", values)
        end
        
        # list of notifiers to load + their config
        notifiers_to_load = options.notifiers
        options.notifiers = {}
        notifiers_to_load.each do |notifier|
          options.notifiers[notifier] = config["#{notifier}-notifier"].symbolize_keys
        end

        # holder for recipients list
        recipients = Flapjack::Inifile.read(options.recipients_filename)
        options.recipients = recipients.all

        options
      end
    end
  end
 
end
