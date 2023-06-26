defmodule SpiInOut do
  @behaviour GenServer
  require Circuits.SPI
  require Logger

  def start_link(pname, spi_name) do
    Logger.debug("#{__MODULE__} start_link: #{inspect(pname)}, #{spi_name} ")
    GenServer.start_link(__MODULE__, spi_name, name: pname)
  end

  def start_link(pname, spi_name, spi_speed, spi_mode) do
    Logger.debug("#{__MODULE__} start_link: #{inspect(pname)}, #{spi_name}, #{spi_speed} ")
    GenServer.start_link(__MODULE__, {spi_name, spi_speed, spi_mode}, name: pname)
  end

  def start_link(pname, spi_name, spi_speed, spi_mode, spi_bitword, spi_delay_us) do
    Logger.debug("#{__MODULE__} start_link: #{inspect(pname)}, #{spi_name}, #{spi_speed} ")
    GenServer.start_link(__MODULE__, {spi_name, spi_speed, spi_mode, spi_bitword, spi_delay_us}, name: pname)
  end

  def send_receive(pname, bitstring) do
    GenServer.call(pname, {:transfer, bitstring})
  end

  def stop(pname), do: GenServer.stop(pname)

#  @impl GenServer
#  def init(spi_name) do
#    Logger.debug("#{__MODULE__} init_open: #{spi_name} ")
#    Circuits.SPI.open(spi_name) # expected to return {:ok, ref}
#  end

  @impl GenServer
  def init({spi_name, spi_speed, spi_mode, spi_bitword, spi_delay_us}) do
    Logger.debug("#{__MODULE__} init_open: #{spi_name} #{spi_speed} #{spi_mode} #{spi_bitword} #{spi_delay_us} ")
    Circuits.SPI.open(spi_name, [{:speed_hz, spi_speed}, {:mode, spi_mode}, {:bit_per_word, spi_bitword}, {:delay_us, spi_delay_us}]) # expected to return {:ok, ref}
  end

#  @impl GenServer
#  def init(spi_name, spi_speed) do
#    Logger.debug("#{__MODULE__} init_open: #{spi_name} ")
#    Circuits.SPI.open(spi_name, [:speed_hz, spi_speed]) # expected to return {:ok, ref}
#  end

  @impl GenServer
  def handle_call({:transfer, bitstring}, _from, spiref) do
#    Logger.debug("#{__MODULE__} :transfer #{inspect(bitstring)} ")
    {:reply, Circuits.SPI.transfer(spiref, bitstring), spiref}
  end

  @impl GenServer
  def terminate(reason, spiref) do
    Logger.debug("#{__MODULE__} terminate: #{inspect(reason)}")
    Circuits.SPI.close(spiref)
    reason
  end
end
