require "test_helper"

class WeatherForecastsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @valid_address = 'valid address'
    @invalid_address = 'invalid address'
    @forecast_data = { current_temperature: 70, high_temperature: 75, low_temperature: 65, daily_forecast: [] }

    WeatherService.any_instance.stubs(:extract_zip_code).with(@valid_address).returns('12345')
    WeatherService.any_instance.stubs(:extract_zip_code).with(@invalid_address).returns(nil)
    WeatherService.any_instance.stubs(:fetch_and_cache_forecast).returns(@forecast_data)
  end

  test "should get index with valid address and return forecast" do
    get weather_forecasts_url, params: { address: @valid_address }
    assert_response :success
    assert_match /Current Temperature:/, response.body
  end

  test "should get index with no address and not show forecast" do
    get weather_forecasts_url
    assert_response :success
    assert_no_match /Current Temperature:/, response.body
  end

  test "should handle invalid address and show error message" do
    get weather_forecasts_url, params: { address: @invalid_address }
    assert_response :success
    assert_match /Couldn&#39;t find a zip code for that address/, response.body
  end

  test "should handle service error gracefully" do
    WeatherService.any_instance.stubs(:fetch_forecast).raises("Service error")
    get weather_forecasts_url, params: { address: @valid_address }
    assert_response :success
    assert_match /Error fetching forecast data/, response.body
  end
end
