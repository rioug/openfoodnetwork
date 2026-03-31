# Force manual loading of rails application to get all env variables from dotenv-rails when running whenever cmd
require File.expand_path('../environment',  __FILE__)

require 'whenever'
require 'yaml'

# Learn more: http://github.com/javan/whenever

env "MAILTO", ENV["SCHEDULE_NOTIFICATIONS"] if ENV["SCHEDULE_NOTIFICATIONS"]

# If we use -e with a file containing specs, rspec interprets it and filters out our examples
job_type :run_file, "cd :path; :environment_variable=:environment bundle exec script/rails runner :task :output"
