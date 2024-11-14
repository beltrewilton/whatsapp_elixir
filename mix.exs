defmodule WhatsappElixir.MixProject do
  use Mix.Project

  @version "0.1.2"
  @repo_url "https://github.com/beltrewilton/whatsapp_elixir"

  def project do
    [
      app: :whatsapp_elixir,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "Open source Elixir wrapper for the WhatsApp Cloud API",
      package: package(),

      # Docs
      name: "whatsapp_elixir",
      docs: [
        name: "whatsapp_elixir",
        source_ref: "v#{@version}",
        source_url: @repo_url,
        homepage_url: @repo_url,
        main: "readme",
        extras: ["README.md"],
        links: %{
          "GitHub" => @repo_url,
          "Sponsor" => "https://github.com/beltrewilton/"
        }
      ]
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @repo_url
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    # export WHATSAPP_FLOW_CRYPTO_PATH=/Users/beltre.wilton/apps/whatsapp_flow_crypto
    # export WHATSAPP_FLOW_CRYPTO_PATH=/home/wilton/plex_env/whatsapp_flow_crypto

    whatsapp_flow_crypto_path = System.get_env("WHATSAPP_FLOW_CRYPTO_PATH")

    [
      {:req, "~> 0.5.6"},
      {:jason, "~> 1.4"},
      {:httpoison, "~> 2.2.1"},
      {:uuid, "~> 1.1"},
      {:ex_doc, "~> 0.27.0", only: :dev, runtime: false},
      {:whatsapp_flow_crypto, path: whatsapp_flow_crypto_path}
    ]
  end
end
