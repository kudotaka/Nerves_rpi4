defmodule M5Env3prs do
  require Logger
  require Libqmp6988

  def init(name, i2c_name, i2c_bus, i2c_addr) do
    Logger.debug("name: #{name} i2c_name: #{i2c_name} i2c_bus: #{i2c_bus} i2c_addr: #{i2c_addr} start...")

    opts = [name: name, i2c_name: i2c_name, i2c_bus: i2c_bus, i2c_addr: i2c_addr]
    Libqmp6988.start_link(opts)
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
    {:ok, retdata} = Libqmp6988.measure(pid)
    pressure = retdata.pressure
    temperature = retdata.temperature
    Logger.info("M5Env3prs pres(hPa): #{Float.round(pressure,1)} temp(degree Celsius): #{Float.round(temperature,1)}")
    Process.sleep(3000)

    loop(pid)
  end

  def stop(i2c_name) do
    Logger.debug("i2c_name: #{i2c_name} stop...")
    Libqmp6988.stop(i2c_name)
  end

end
