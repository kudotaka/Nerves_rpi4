defmodule UartMhz19 do

  require Logger

  def init() do
    Logger.debug("#{__MODULE__}: Uartmhz19 start...")
    {:ok, pid} = LibMhZ19.start_link()
    Process.sleep(2000)
    loop(pid)
  end

  defp loop(pid) do
    {:ok, result} = LibMhZ19.measure(pid)
    Process.sleep(100)
    # 表示
    Logger.info("CO2 #{result}")
    Process.sleep(2000)
    loop(pid)
  end

end
