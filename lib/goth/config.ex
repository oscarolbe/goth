defmodule Goth.Config do
  @moduledoc """
  `Goth.Config` is a `GenServer` that holds the current configuration.
  This configuration is loaded from one of three places:

  1. a JSON string passed in via your application's config
  2. a ENV variable passed in via your application's config
  3. Google's metadata service (note: this only works if running in GCP)

  The `Goth.Config` server exists mostly for other parts of your application
  (or other libraries) to pull the current configuration state,
  via `Goth.Config.get/1`. If necessary, you can also set config values via
  `Goth.Config.set/2`
  """

  use GenServer
  alias Goth.Client

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def init(:ok) do
    case Application.get_env(:goth, :json) do
      nil  -> {:ok, Application.get_env(:goth, :config,
                %{"token_source" => :metadata,
                  "project_id" => Client.retrieve_metadata_project()})}
      {:system, var} -> {:ok, decode_json(System.get_env(var)) }
      json -> {:ok, decode_json(json)}
    end
  end

  defp decode_json(json) when is_list(json) do
    json
    |> Enum.into(%{})
    |> stringify_keys()
    |> Map.put("token_source", :oauth)
  end

  defp stringify_keys(map) do
    map
    |> Enum.map(fn {k, v} ->
      if (!is_atom(k)) do
        {k, v}
      else
        {Atom.to_string(k), v}
      end
     end)
    |> Enum.into(%{})
  end

  # Decodes JSON (if configured) and sets oauth token source
  defp decode_json(json) do
    json
    |> Poison.decode!()
    |> Map.put("token_source", :oauth)
  end

  def set(key, value) when is_atom(key), do: key |> to_string |> set(value)
  def set(key, value) do
    GenServer.call(__MODULE__, {:set, key, value})
  end

  def get(key) when is_atom(key), do: key |> to_string |> get
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def handle_call({:set, key, value}, _from, keys) do
    {:reply, :ok, Map.put(keys, key, value)}
  end

  def handle_call({:get, key}, _from, keys) do
    {:reply, Map.fetch(keys, key), keys}
  end
end
