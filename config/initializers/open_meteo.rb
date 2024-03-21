require "open_meteo"

OpenMeteo.configure do |config|
  # config.host = "api.my-own-open-meteo.com"
  config.logger = Rails.logger
  # config.api_key = "your_open_meteo_api_key"
end
