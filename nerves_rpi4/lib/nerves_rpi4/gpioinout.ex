defmodule GpioInOut do
  @behaviour GenServer
  require Circuits.GPIO
  require Logger

  def start_link(pname, gpio_no, in_out) do
    Logger.debug("#{__MODULE__} start_link: #{pname}, #{gpio_no}, #{in_out} ")
    GenServer.start_link(__MODULE__, {pname, gpio_no, in_out}, name: pname)
  end

  def write(pname, :true), do: GenServer.cast(pname, {:write, 1})
  def write(pname, :false), do: GenServer.cast(pname, {:write, 0})
  def write(pname, val), do: GenServer.cast(pname, {:write, val})

  def read(pname), do: GenServer.call(pname, :read)
  def stop(pname), do: GenServer.stop(pname)

  @impl GenServer
  def init({pname, gpio_no, in_out}) do
#    Logger.debug("#{__MODULE__} init_open: #{pname} #{gpio_no}, #{in_out} ")
    Circuits.GPIO.open(gpio_no, in_out) # expected to return {:ok, gpioref}
  end

  @impl GenServer
  def handle_cast({:write, val}, gpioref) do
#    Logger.debug("#{__MODULE__} :write #{val} ")
    Circuits.GPIO.write(gpioref, val)
    {:noreply, gpioref}
  end

  @impl GenServer
  def handle_call(:read, _from, gpioref) do
    {:reply, {:ok, Circuits.GPIO.read(gpioref)}, gpioref}
  end

  @impl GenServer
  def terminate(reason, gpioref) do
    Logger.debug("#{__MODULE__} terminate: #{inspect(reason)}")
    Circuits.GPIO.close(gpioref)
    reason
  end
end
