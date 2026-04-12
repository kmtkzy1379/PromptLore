Rack::Attack.throttle("logins/ip", limit: 5, period: 60) do |req|
  req.ip if req.path == "/users/sign_in" && req.post?
end

Rack::Attack.throttle("signups/ip", limit: 3, period: 60) do |req|
  req.ip if req.path == "/users" && req.post?
end

Rack::Attack.throttle("requests/ip", limit: 300, period: 300) do |req|
  req.ip
end
