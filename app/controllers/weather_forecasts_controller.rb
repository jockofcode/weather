class WeatherForecastsController < ApplicationController
  def index
    address = params[:address]
    weather_service = WeatherService.new(address)

    if address.blank?
      @forecast = nil
      return
    end

    @zip_code, @forecast, @from_cache = weather_service.fetch_forecast
    @error_message = "Couldn't find a zip code for that address" if @zip_code.blank?
  rescue => e
    Rails.logger.error("Error fetching forecast data: #{e.message}")
    @error_message = "Error fetching forecast data. Please try again later."
  end
end
