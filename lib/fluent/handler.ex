defmodule Fluent.ConnectionError do
  defexception [:host, :port, :reason]

  def message(exception) do
    "cannot connect to #{exception.host}:#{exception.port} by #{exception.reason}"
  end
end

defmodule Fluent.Handler do
  use GenEvent
  alias __MODULE__

  defstruct [:tag, :host, :port, :socket]

  def init({tag, host, port}) do
    host = String.to_char_list(host)
    {:ok, socket} = connect_to_fluentd(host, port)
    {:ok, %Handler{tag: tag, host: host, port: port, socket: socket}}
  end

  def handle_event({tag, data}, %Handler{} = state) do
    content = prepare_content(tag, data, state)
    send_to_fluentd(content, state, 3)
  end

  def terminate(_reason, %Handler{socket: socket}) do
    :gen_tcp.close(socket)
  end

  defp connect_to_fluentd(host, port) do
    :gen_tcp.connect(host, port, [:binary, {:packet, 0}])
  end

  defp prepare_content(tag, data, %Handler{tag: top_tag}) do
    {msec, sec, _} = :os.timestamp
    tag = prepare_tag(top_tag, tag)
    content = [tag, msec * 1000000 + sec, data]

    content
    |> Msgpax.pack!
    |> IO.iodata_to_binary
  end

  defp prepare_tag(top_tag, tag) do
    tag = tag || ""
    if top_tag, do: "#{top_tag}.#{tag}", else: tag
  end

  defp send_to_fluentd(_content, %Handler{host: host, port: port}, 0) do
    raise Fluent.ConnectionError, host: host, port: port, reason: "retry limit"
  end

  defp send_to_fluentd(content, %Handler{socket: socket, host: host, port: port} = state, count) do
    case :gen_tcp.send(socket, content) do
      :ok ->
        {:ok, state}
      {:error, :closed} ->
        {:ok, socket} = connect_to_fluentd(host, port)
        send_to_fluentd(content, %Handler{state | socket: socket}, count - 1)
      {:error, reason} ->
        raise Fluent.ConnectionError, host: host, port: port, reason: Atom.to_string(reason)
    end
  end
end
