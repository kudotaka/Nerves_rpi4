defmodule M5Env3V2 do
  require Logger
  require LibSht3x

  def init(name, i2c_name, i2c_bus, i2c_addr) do
    Logger.debug("name: #{name} i2c_name: #{i2c_name} i2c_bus: #{i2c_bus} i2c_addr: #{i2c_addr} start...")

    opts = [name: name, i2c_name: i2c_name, i2c_bus: i2c_bus, i2c_addr: i2c_addr]
    LibSht3x.start_link(opts)
    |> init_result()
  end
  defp init_result({:ok, pid}) do
    Process.sleep(100)
    loop(pid)
  end
  defp init_result({:error, _pid}) do
    Logger.debug("device not found.")
  end

  defp loop(pid) do
    {:ok, retdata} = LibSht3x.measure(pid)
    temp = retdata.temperature
    humi = retdata.humidity

    Logger.info("M5Env3V2 temp(degree Celsius): #{Float.round(temp,1)} , humi(%): #{Float.round(humi,1)}")
    Process.sleep(3000)

    loop(pid)
  end

  def stop(i2c_name) do
    Logger.debug("i2c_name: #{i2c_name} stop...")
    LibSht3x.stop(i2c_name)
  end
end
