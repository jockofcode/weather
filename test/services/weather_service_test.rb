require 'test_helper'

class WeatherServiceTest < ActiveSupport::TestCase
  setup do
    stub_request(:get, "https://api.open-meteo.com/v1/forecast")
      .to_return(body: '{"current": {"temperature_2m": 70}, "daily": {"time": ["2024-01-01"], "temperature_2m_max": [75], "temperature_2m_min": [65]}}', status: 200)
    stub_request(:get, "https://api.open-meteo.com/v1/forecast?current=temperature_2m&daily=temperature_2m_max,temperature_2m_min&hourly=&latitude=45.0&longitude=-93.0&temperature_unit=fahrenheit&timezone=auto")
      .to_return(status: 200, body: '{"current": {"temperature_2m": 70}, "daily": {"time": ["2024-01-01"], "temperature_2m_max": [75], "temperature_2m_min": [65]}}', headers: {})

    Geocoder.stubs(:search).with('484 West, WallaWalla, Washington').returns([OpenStruct.new(postal_code: '12345')])
    Geocoder.stubs(:coordinates).with('484 West, WallaWalla, Washington').returns([45.0, -93.0])

    Rails.cache.clear
    @original_cache_store = Rails.configuration.cache_store
    Rails.configuration.cache_store = :memory_store
    Rails.cache = ActiveSupport::Cache.lookup_store(Rails.configuration.cache_store)
    Rails.application.config.action_controller.perform_caching = true
  end

  teardown do
    Rails.cache.clear
    Rails.configuration.cache_store = @original_cache_store
    Rails.cache = ActiveSupport::Cache.lookup_store(Rails.configuration.cache_store)
    Rails.application.config.action_controller.perform_caching = false
  end

  test 'extracts correct zip code from address' do
    service = WeatherService.new('484 West, WallaWalla, Washington')
    assert_equal '12345', service.send(:extract_zip_code, '484 West, WallaWalla, Washington')
  end

  test 'fetches forecast from API when not cached' do
    service = WeatherService.new('484 West, WallaWalla, Washington')
    _zip_code, forecast, from_cache = service.fetch_forecast

    assert_not_nil forecast
    assert_equal 70, forecast[:current_temperature]
    assert_equal from_cache, false
  end

  test 'returns cached forecast when available' do
    Rails.cache.write([:forecast, '12345'], { current_temperature: 70 }, expires_in: 10.minutes)
    service = WeatherService.new('484 West, WallaWalla, Washington')
    _zip_code, forecast, from_cache = service.fetch_forecast

    assert_not_nil forecast
    assert_equal 70, forecast[:current_temperature]
    assert from_cache
  end

  test 'parse_forecast_response correctly parses the response' do
    response = OpenStruct.new(
      body: '{"current": {"temperature_2m": 70}, "daily": {"time": ["2024-01-01", "2024-01-02"], "temperature_2m_max": [75, 55], "temperature_2m_min": [65, 35]}}'
    )

    expected_daily_forecast = [
      { date: "2024-01-01", high: 75, low: 65 },
      { date: "2024-01-02", high: 55, low: 35 },
    ]

    service = WeatherService.new('484 West, WallaWalla, Washington')
    parsed_forecast = service.send(:parse_forecast_response, response)

    assert_equal 70, parsed_forecast[:current_temperature]
    assert_equal 75, parsed_forecast[:high_temperature]
    assert_equal 65, parsed_forecast[:low_temperature]
    assert_equal expected_daily_forecast, parsed_forecast[:daily_forecast]
  end
end
