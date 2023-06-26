defmodule LibSht3x do
  use GenServer
  require I2cInOut
  require Logger

#  @sHT3X_COMMAND_INITIALISE   "0xBE, 0x08"
#  @sHT3X_COMMAND_MEASURE      "0x2C, 0x06"

  def start_link(opts \\ []) do
    name = opts[:name] || __MODULE__
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def measure(pid) do
    GenServer.call(pid, :measure)
  end

  def stop(name), do: GenServer.stop(name)

  @impl GenServer
  def init(opts \\ []) do
    i2c_name = opts[:i2c_name]
    i2c_bus = opts[:i2c_bus]
    i2c_addr = opts[:i2c_addr]
    Logger.debug("name: #{opts[:name]} i2c_name: #{opts[:i2c_name]} i2c_bus: #{opts[:i2c_bus]} i2c_addr: #{opts[:i2c_addr]}")
    I2cInOut.start_link(i2c_name, i2c_bus)
    Process.sleep(100)

    I2cInOut.isdevice(i2c_name, i2c_addr)
    |> handle_init(i2c_name, i2c_addr)

  end

  defp handle_init({:ok, true}, i2c_name, i2c_addr) do
    I2cInOut.write(i2c_name, i2c_addr, <<0xBE, 0x08>>)
#    I2cInOut.write(i2c_name, i2c_addr, <<@sHT3X_COMMAND_INITIALISE>>)
    Process.sleep(100)
    {:ok, %{i2c_name: i2c_name, i2c_addr: i2c_addr}}
  end
  defp handle_init({_, false}, i2c_name, i2c_addr) do
    {:error, %{i2c_name: i2c_name, i2c_addr: i2c_addr, reason: "device not found. #{i2c_name} #{i2c_addr}"}}
  end

  @impl GenServer
  def handle_call(:measure, _from, state) do
    {:reply, measure_sensor(state), state}
  end

  defp measure_sensor(state) do
    I2cInOut.write(state.i2c_name, state.i2c_addr, <<0x2C, 0x06>>)
#    I2cInOut.write(state.i2c_name, state.i2c_addr, <<@sHT3X_COMMAND_MEASURE>>)
    Process.sleep(100)
    I2cInOut.read(state.i2c_name, state.i2c_addr, 6)
    |> handle_data(state)

  end

  defp handle_data({:ok, {:ok, rawdata}}, _state) do
    #バイト分割
    #0:cTemp msb, 1:cTemp lsb, 2:cTemp crc, 3:humidity msb, 4:humidity lsb, 5:humidity crc
    <<t0, t1, _tc2, h3, h4, _hc5>> = rawdata

    # 湿度に変換（データシートに換算方法あり）
    humi = ((((h3 * 256.0) + h4) * 100) / 65535.0);

    # 温度に変換（データシートに換算方法あり）
    temp = ((((t0 * 256.0) + t1) * 175) / 65535.0) - 45;

    {:ok, %{temperature: temp, humidity: humi}}
  end

  defp handle_data({:ok, {:error, reason}}, _state) do
    Logger.debug("handle_data: #{reason}")
    {:error, reason}
  end

  defp handle_data(_, state) do
    Process.sleep(500)
    measure_sensor(state)
  end

  @impl GenServer
  def terminate(reason, {i2c_name}) do
    Logger.debug("#{__MODULE__} terminate: #{inspect(reason)}")
    I2cInOut.stop(i2c_name)
#    Circuits.I2C.close(i2cref)
    reason
  end
end
