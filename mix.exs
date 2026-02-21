defmodule Fred.MixProject do
  use Mix.Project

  def project do
    [
      app: :fred,
      version: project_version(),
      elixir: "~> 1.18",
      name: "Fred",
      source_url: "https://github.com/akoutmos/fred",
      homepage_url: "https://hex.pm/packages/fred",
      description: "An Elixir client for the Federal Reserve Economic Data API",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      name: "fred",
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md VERSION),
      licenses: ["MIT"],
      maintainers: ["Alex Koutmos"],
      links: %{
        "GitHub" => "https://github.com/akoutmos/fred",
        "Sponsor" => "https://github.com/sponsors/akoutmos"
      }
    ]
  end

  defp docs do
    livebooks =
      __DIR__
      |> Path.join("livebooks")
      |> File.ls!()
      |> Enum.map(fn livebook ->
        Path.join("livebooks", livebook)
      end)
      |> Enum.sort()

    [
      main: "readme",
      source_ref: "master",
      logo: "guides/images/logo.png",
      groups_for_modules: [
        "Data API Modules": [
          Fred.Categories,
          Fred.Maps,
          Fred.Releases,
          Fred.Series,
          Fred.Sources,
          Fred.Tags
        ],
        "Supporting Modules": [
          Fred.Client,
          Fred.Geo,
          Fred.Telemetry,
          Fred.Telemetry.Logger
        ]
      ],
      extras: ["README.md", "CHANGELOG.md" | livebooks],
      groups_for_extras: [
        General: ["README.md", "CHANGELOG.md"],
        Livebooks: Path.wildcard("livebooks/*.livemd")
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Required dependencies
      {:req, "~> 0.5"},
      {:telemetry, "~> 1.3"},
      {:geo, "~> 3.6 or ~> 4.0"},

      # Development deps
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: :dev},
      {:doctor, "~> 0.22", only: :dev}
    ]
  end

  defp aliases do
    [
      docs: ["docs", &copy_files/1]
    ]
  end

  defp project_version do
    "VERSION"
    |> File.read!()
    |> String.trim()
  end

  defp copy_files(_) do
    # Set up directory structure
    File.mkdir_p!("./doc/guides/images")

    # Copy over image files
    "./guides/images/"
    |> File.ls!()
    |> Enum.each(fn image_file ->
      File.cp!("./guides/images/#{image_file}", "./doc/guides/images/#{image_file}")
    end)
  end
end
