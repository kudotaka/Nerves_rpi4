defmodule UartMhz19 do
  require Logger
  require LibMhZ19

  def init(name, tty) do
    Logger.debug("#{__MODULE__}: Uartmhz19 start... tty: #{tty}")

    opts = [name: name, tty: tty]
    {:ok, pid} = LibMhZ19.start_link(opts)
    Process.sleep(2000)
    loop(pid)
  end

  defp loop(pid) do
    {:ok, result} = LibMhZ19.measure(pid)
    Process.sleep(100)

    Logger.info("Mhz19 CO2 #{result}")
    Process.sleep(3000)

    loop(pid)
  end

end
