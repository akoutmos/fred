import Config

config :fred,
  api_key: System.fetch_env!("FRED_API_KEY")
