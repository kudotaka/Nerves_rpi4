defmodule LibLedBlink do
  use GenServer
  require GpioInOut
  require Logger

  def start_link(opts \\ []) do
#    Logger.debug("start_link!")
    name = opts[:name] || __MODULE__
    Logger.debug("name: #{name} gpio_name: #{opts[:gpio_name]} gpio_no: #{opts[:gpio_no]}")
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def led_blink(pid) do
#    Logger.debug("led_blink!")
    GenServer.call(pid, :led_blink)
  end

  def led_on(pid) do
#    Logger.debug("led_on!")
    GenServer.call(pid, :led_on)
  end

  def led_off(pid) do
#    Logger.debug("led_off!")
    GenServer.call(pid, :led_off)
  end

  def stop(led_name) do
#    Logger.debug("stop!")
    GenServer.stop(led_name)
  end

      @impl GenServer
  def init(opts \\ []) do
#    Logger.debug("init!")
    name = opts[:name]
    gpio_name = opts[:gpio_name]
    gpio_no = opts[:gpio_no]
#    Logger.debug("name: #{opts[:name]} gpio_name: #{opts[:gpio_name]} gpio_no: #{opts[:gpio_no]}")
    GpioInOut.start_link(name, gpio_no, :output)
    {:ok, %{pname: name, gpio_name: gpio_name, gpio_no: gpio_no, on_delay: opts[:on_delay], off_delay: opts[:off_delay]}}
  end

  @impl GenServer
  def handle_call(:led_blink, _from, state) do
    {:reply, blink(state), state}
  end

  @impl GenServer
  def handle_call(:led_on, _from, state) do
    {:reply, on(state), state}
  end

  @impl GenServer
  def handle_call(:led_off, _from, state) do
    {:reply, off(state), state}
  end

  @impl GenServer
  def terminate(reason, led_name) do
    Logger.debug("#{__MODULE__} terminate: #{inspect(reason)}")
    GpioInOut.stop(led_name)
    reason
  end

  defp blink(state) do
    Logger.debug("blink #{state.pname} on...")
#    GpioInOut.write(state.gpio_name, :true)
    GpioInOut.write(state.pname, :true)
    Process.sleep(state.on_delay)
    Logger.debug("blink #{state.pname} off...")
#    GpioInOut.write(state.gpio_name, :false)
    GpioInOut.write(state.pname, :false)
    Process.sleep(state.off_delay)
    {:ok, %{}}
  end

  defp on(state) do
#    Logger.debug("on #{state.gpio_name} on...")
#    GpioInOut.write(state.gpio_name, :true)
    GpioInOut.write(state.pname, :true)
    Process.sleep(state.on_delay)
    {:ok, %{}}
  end

  defp off(state) do
#    Logger.debug("off #{state.gpio_name} off...")
#    GpioInOut.write(state.gpio_name, :false)
    GpioInOut.write(state.pname, :false)
    Process.sleep(state.off_delay)
    {:ok, %{}}
  end

end
