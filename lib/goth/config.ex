defmodule Goth.Config do
  @moduledoc """
  Read config from environment
  """

  def data() do
    case Application.get_env(:goth, :json) do
      nil  -> {:ok, Application.get_env(:goth, :config,
                %{"token_source" => :metadata,
                  "project_id" => Client.retrieve_metadata_project()})}
      {:system, var} -> {:ok, decode_json(System.get_env(var)) }
      json -> decode_json(json)
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
      if is_atom(k) do
        {Atom.to_string(k), v}
      else
        {k, v}
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

  def get(key) when is_atom(key), do: key |> to_string |> get
  def get(key) do
    {:ok, Map.get(data(), key)}
  end
end
