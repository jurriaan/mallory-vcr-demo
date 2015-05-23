When(/^the client does an external GET request to "([^"]*)"$/) do |url|
  @last_response = `env https_proxy=https://localhost:9999 http_proxy=https://localhost:9999 curl -s '#{url}'`
end

Then(/^the response should include "([^"]*)"$/) do |string|
  expect(@last_response).to include(string)
end
