# Service class for fetching weather forecasts based on an address
class WeatherService
  # Initializes the service with a specific address
  # @param address [String] The address for which the weather forecast will be fetched
  def initialize(address)
    @address = address
  end

  # Fetches the weather forecast for the initialized address
  # @return [Array] An array containing the zip code, forecast data (or nil if not found),
  #                 and a boolean indicating whether the data was fetched from cache
  def fetch_forecast
    zip_code = extract_zip_code(@address)
    return [zip_code, nil, false] if zip_code.blank?

    # Attempt to retrieve cached forecast data for the zip code
    cached_data = Rails.cache.read([:forecast, zip_code])
    if cached_data
      [zip_code, cached_data, true]
    else
      # Fetches and caches the forecast if not available in cache
      [zip_code, fetch_and_cache_forecast(@address, zip_code), false]
    end
  end

  private

  # Extracts the zip code from the given address using the Geocoder gem
  # @param address [String] The address to extract the zip code from
  # @return [String, nil] The extracted zip code or nil if not found
  def extract_zip_code(address)
    full_address = Geocoder.search(address).first
    full_address&.postal_code
  end

  # Fetches the weather forecast for the given address and zip code,
  # caches the result, and returns the forecast data
  # @param address [String] The address for the forecast
  # @param zip_code [String] The zip code of the address
  # @return [Hash] The fetched weather forecast data
  def fetch_and_cache_forecast(address, zip_code)
    coordinates = Geocoder.coordinates(address)
    forecast = fetch_weather_data(coordinates)
    Rails.cache.write([:forecast, zip_code], forecast, expires_in: 30.minutes)
    forecast
  end

  # Fetches the weather data from the OpenMeteo API using the given coordinates
  # @param coordinates [Array<Float>] The latitude and longitude for the forecast
  # @return [Hash] The weather data fetched from the API
  def fetch_weather_data(coordinates)
    args = {
      "latitude" => coordinates[0],
      "longitude" => coordinates[1],
      "temperature_unit" => "fahrenheit",
      "current" => "temperature_2m",
      "hourly" => "",
      "daily" => "temperature_2m_max,temperature_2m_min",
      "timezone" => "auto"
    }

    weather_url = "https://api.open-meteo.com/v1/forecast?" + URI.encode_www_form(args)
    response = HTTParty.get(weather_url)
    parse_forecast_response(response)
  end

  # Parses the forecast response from the API and structures the weather data
  # @param response [HTTParty::Response] The raw HTTP response from the weather API
  # @return [Hash] The parsed and structured forecast data
  def parse_forecast_response(response)
    forecast_response = JSON.parse(response.body)
    forecast_response_daily = forecast_response["daily"]

    daily_forecast = forecast_response_daily["time"].zip(
      forecast_response_daily["temperature_2m_max"],
      forecast_response_daily["temperature_2m_min"]
    ).map { |date, high, low| { date: date, high: high, low: low } }

    {
      current_temperature: forecast_response.dig("current","temperature_2m"),
      high_temperature: daily_forecast.first[:high],
      low_temperature: daily_forecast.first[:low],
      daily_forecast: daily_forecast,
    }
  end
end
