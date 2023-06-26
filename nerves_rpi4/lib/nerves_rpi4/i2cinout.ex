defmodule I2cInOut do
  @behaviour GenServer
  require Circuits.I2C
  require Logger

  def start_link(pname, i2c_bus) do
    Logger.debug("#{__MODULE__} start_link: #{inspect(pname)}, #{i2c_bus} ")
    GenServer.start_link(__MODULE__, {i2c_bus}, name: pname)
  end

  def write(pname, i2c_addr, data, retries \\ []) do
    GenServer.cast(pname, {:write, i2c_addr, data, retries})
  end

  def read(pname, i2c_addr, bytes, retries \\ []) do
    GenServer.call(pname, {:read, i2c_addr, bytes, retries})
  end

  def writeread(pname, i2c_addr, data, bytes, retries \\ []) do
    GenServer.call(pname, {:writeread, i2c_addr, data, bytes, retries})
  end

  def isdevice(pname, i2c_addr) do
    GenServer.call(pname, {:devicepresent, i2c_addr})
  end

  def stop(pname), do: GenServer.stop(pname)

  @impl GenServer
  def init({i2c_bus}) do
    Logger.debug("#{__MODULE__} init_open: #{inspect(i2c_bus)} ")
    Circuits.I2C.open(i2c_bus) # expected to return {:ok, i2cref}
  end

  @impl GenServer
  def handle_cast({:write, i2c_addr, data, retries}, i2cref) do
    Circuits.I2C.write(i2cref, i2c_addr, data, retries)
    {:noreply, i2cref}
  end

  @impl GenServer
  def handle_call({:read, i2c_addr, bytes, retries}, _from, i2cref) do
    {:reply, {:ok, Circuits.I2C.read(i2cref, i2c_addr, bytes, retries)}, i2cref}
  end

  @impl GenServer
  def handle_call({:writeread, i2c_addr, data, bytes, retries}, _from, i2cref) do
    {:reply, {:ok, Circuits.I2C.write_read(i2cref, i2c_addr, data, bytes, retries)}, i2cref}
  end

  @impl GenServer
  def handle_call({:devicepresent, i2c_addr}, _from, i2cref) do
    {:reply, {:ok, Circuits.I2C.device_present?(i2cref, i2c_addr)}, i2cref}
  end

  @impl GenServer
  def terminate(reason, i2cref) do
    Logger.debug("#{__MODULE__} terminate: #{inspect(reason)} #{inspect(i2cref)}")
    Circuits.I2C.close(i2cref)
    reason
  end
end
