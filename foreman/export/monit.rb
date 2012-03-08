module Foreman
  module Export
    class Monit < Foreman::Export::Base

      attr_reader :pid, :checkfile

      def initialize(location, engine, options={})
        super
        @location = File.expand_path(@location)
        @pid = options[:pid]
        @checkfile = options[:checkfile]
      end

      def export
        error("Must specify a location") unless location

        FileUtils.mkdir_p location

        @app ||= File.basename(engine.directory)
        @user ||= app

        template_root = self.template
        log_root = self.log || "/var/log/#{app}"
        pid_root = self.pid || "/var/run/#{app}"

        @checkfile ||= "/var/lock/subsys/#{app}.restart"

        engine.procfile.entries.each do |process|
          wrapper_template = export_template("monit", "wrapper.sh.erb", template_root)
          wrapper_config   = ERB.new(wrapper_template, 0, "-").result(binding)
          write_file wrapper_path_for(process), wrapper_config
          FileUtils.chmod 0755, wrapper_path_for(process)
        end

        monitrc_template = export_template("monit", "monitrc.erb", template_root)
        monitrc_config   = ERB.new(monitrc_template, 0, "-").result(binding)
        write_file "#{location}/#{app}.monitrc", monitrc_config
      end

      def wrapper_path_for(process)
        File.join(location, "#{app}-#{process.name}.sh")
      end

    end
  end
end
