module Ubea
  module Log
    @semaphore ||= Mutex.new

  module_function

    def info message, options = {}
      options = {
        output: $stdout,
        timestamp: true
      }.merge(options)

      message = "#{Time.now} #{message}" if options.fetch(:timestamp)

      @semaphore.synchronize { options.fetch(:output).puts message }
    end

    def debug message, options = {}
      info message, options if Ubea.config.debug
    end

    def warn message, options = {}
      options = {output: $stderr}.merge(options)

      info "[WARN] #{message}", options
    end
  end
end

