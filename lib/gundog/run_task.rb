if defined?(::Rails)
  class RunTask < Rails::Railtie
    rake_tasks do
      load 'tasks/run.rake'
    end
  end
end
