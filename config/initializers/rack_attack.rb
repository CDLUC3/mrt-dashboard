###############################################
# Rack-Attack configuration for rate limiting
###############################################

# Exemptions
# ------------------

# IPs to allow outright
Rack::Attack.safelist_ip('127.0.0.1')
Rack::Attack.safelist_ip('::1')
# TODO: Add Dryad IP

# Blocks
# -------------------

# IPs to block outright
# Rack::Attack.blocklist_ip("5.6.7.8")

# Set a long block period for any client that is explicitly looking for security holes
Rack::Attack.blocklist('malicious_clients') do |req|
  Rack::Attack::Fail2Ban.filter("fail2ban_malicious_#{req.ip}", maxretry: 1, findtime: 1.day, bantime: 1.day) do
    CGI.unescape(req.query_string) =~ %r{/etc/passwd} ||
      req.path.include?('/etc/passwd') ||
      req.path.include?('wp-admin') ||
      req.path.include?('wp-login') ||
      /\S+\.php/.match?(req.path)
  end
end

# Throttling
# -------------------

# Throttling allows no more than `limit` requests per `period`
# Each throttle takes a block that returns a "discriminator" for the user and type of call.
# Rack-attack counts the requests for each discriminator within the period and manages the
# throttle notifications.
#
# Each throttle is independent, so it is possible for a single request to be counted in multiple
# discriminators.

# Baseline throttle all requests by IP
# But don't return anything for /assets, which are just part of each page and should not be tracked.
Rack::Attack.throttle('all_requests_by_IP', limit: 100, period: 1.minute) do |req|
  req.ip unless req.path.start_with?('/assets') 
end

# When a client is throttled, return useful information in the response
Rack::Attack.throttled_response = ->(env) do
  match_data = env['rack.attack.match_data']
  now = match_data[:epoch_time]

  headers = {
    'RateLimit-Limit' => match_data[:limit].to_s,
    'RateLimit-Remaining' => '0',
    'RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s
  }

  [429, headers, ["Request rejected due to rate limits.\n"]]
end

# Log the blocked requests
ActiveSupport::Notifications.subscribe(/rack_attack/) do |name, _start, _finish, _request_id, payload|
  req = payload[:request]
  Rails.logger.info "[Rack::Attack][Blocked] name: #{name}, rule: #{req.env['rack.attack.matched']} remote_ip: #{req.ip}, " \
                    "path: #{req.path}, agent: #{req.user_agent}"
end