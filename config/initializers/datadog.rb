if ENV['DATADOG_RAILS_APM']
  Datadog.configure do |c|
    c.use :rails, service_name: 'rails'
    c.use :delayed_job, service_name: 'delayed_job'
    c.use :dalli, service_name: 'memcached'
    c.analytics_enabled = true
  end
end
