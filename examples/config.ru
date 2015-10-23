require 'bundler/setup'

run ->(env) {
  puts 'req'
  sleep (rand * 5).ceil
  [200, {'Content-Type' => 'application/json'}, [%({"date": "#{Time.now.to_s}"})]]
}
