defmodule Fluent do
  def add_mon_handler(ref, tag, options \\ []) do
    host = options[:host] || "localhost"
    port = options[:port] || 24224

    GenEvent.add_mon_handler(ref, Fluent.Handler, {tag, host, port})
  end

  def post(ref, tag, data) do
    GenEvent.notify(ref, {tag, data})
  end
end
