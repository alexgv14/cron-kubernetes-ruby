# frozen_string_literal: true

require "singleton"

module CronKubernetes
  # A singleton that creates and holds the scheduled commands.
  class Scheduler
    include Singleton
    attr_reader :schedule

    def initialize
      @schedule = []
    end

    def rake(task, schedule:, name: nil)
      rake_command = "bundle exec rake #{task} --silent"
      rake_command = "RAILS_ENV=#{rails_env} #{rake_command}" if rails_env
      @schedule << CronJob.new(schedule: schedule, command: make_command(rake_command), name: name)
    end

    def runner(ruby_command, schedule:, name: nil)
      env = nil
      env = "-e #{rails_env} " if rails_env
      runner_command = "bin/rails runner #{env}'#{ruby_command}'"
      @schedule << CronJob.new(schedule: schedule, command: make_command(runner_command), name: name)
    end

    def command(command, schedule:, name: nil)
      @schedule << CronJob.new(schedule: schedule, command: make_command(command), name: name)
    end

    private

    def make_command(command)
      CronKubernetes.job_template.map do |arg|
        if arg == ":job"
          "cd #{root} && #{command} #{CronKubernetes.output}"
        else
          arg
        end
      end
    end

    def rails_env
      ENV["RAILS_ENV"]
    end

    def root
      return Rails.root if defined? Rails
      Dir.pwd
    end
  end
end
