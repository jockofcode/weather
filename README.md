# Weather Service

## Overview
Weather Service is a Ruby on Rails application that provides weather forecasts based on a given address. It utilizes the Open-Meteo API to fetch weather data and caches the results to improve performance.

## Features
- Address-based weather forecasting
- Caching of weather data to reduce API calls
- Error handling for unavailable zip codes or forecast data
- Uses Redis for caching to address immediate scaling

## Requirements
- Ruby on Rails 7
- HTTParty gem for making HTTP requests
- Geocoder gem for extracting zip codes from addresses

## Installation

1. Ensure you have Ruby on Rails 7 and Bundler installed.
2. Clone the repository to your local machine.
3. Navigate to the project directory and run `bundle install` to install the required gems.

## Usage

1. Start the Rails server using `rails s`.
2. Access the application through a web browser at `http://localhost:3000`.
3. Use the endpoint `/weather_forecasts` to get the weather forecast for the specified address.

## Code Structure

- `app/services/weather_service.rb`: Contains the `WeatherService` class that handles the logic for fetching and caching weather data.
- `app/controllers/weather_forecasts_controller.rb`: Manages the web requests and interacts with `WeatherService` to get the weather data.
- `app/views/weather_forecasts/index.html.erb`: The view template that displays the weather forecast.

## How It Works

1. The `WeatherForecastsController` receives a request with an address.
2. It initializes a `WeatherService` instance with the provided address.
3. `WeatherService` extracts the zip code from the address using Geocoder.
4. It checks if the forecast for the zip code is cached.
   - If cached, it returns the cached data.
   - If not, it fetches the forecast from the Open-Meteo API, caches it, and then returns it.
5. The controller then renders the view with the fetched forecast data.

## Caching Strategy

- Weather data is cached based on the zip code to avoid unnecessary API calls.
- Cached data expires in 30 minutes, ensuring that users receive up-to-date forecasts.

## Error Handling

- If the zip code cannot be extracted from the address, an error message is displayed.
- Any errors during the fetching of weather data are logged and an error message is shown to the user.

## Dependencies

- `HTTParty`: Used for making HTTP requests to the Open-Meteo API.
- `Geocoder`: Used for extracting the zip code from the provided address.

## Contributing

Contributions to improve Weather Service are welcome. Please follow the standard GitHub pull request process to submit your changes.

## WeatherService Class
- **Responsibilities**:
  - Fetches and caches weather data based on address or zip code.
  - Extracts zip code from the given address.
  - Fetches weather data from Open-Meteo API.
  - Caches weather data to optimize performance.
- **Key Methods**:
  - `initialize(address)`: Sets up the service with the specified address.
  - `fetch_forecast`: Main method to retrieve the forecast, handling caching logic.
  - `extract_zip_code(address)`: Extracts the zip code from the address.
  - `fetch_and_cache_forecast(address, zip_code)`: Retrieves weather data from the API and caches it.
  - `fetch_weather_data(coordinates)`: Fetches weather data from the API using geographical coordinates.
  - `parse_forecast_response(response)`: Parses the API response into a structured format.

## WeatherForecastsController Class
- **Responsibilities**:
  - Interacts with the `WeatherService` to get weather data.
  - Handles HTTP requests and responses.
  - Manages error handling and logging.
- **Key Methods**:
  - `index`: The main action that responds to web requests, orchestrating the process of fetching the forecast and handling errors.

#### Views (index.html.erb)
- **Responsibilities**:
  - Displays the weather forecast to the user.
  - Presents error messages when applicable.

### How Objects Interact
- The `WeatherForecastsController` receives a user request, then uses `WeatherService` to fetch the corresponding weather data.
- `WeatherService` performs the heavy lifting of geocoding the address, fetching the weather data from the Open-Meteo API, caching the results, and returning the formatted forecast data back to the controller.
