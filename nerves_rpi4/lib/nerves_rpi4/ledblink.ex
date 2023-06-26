defmodule LedBlink do
  require Logger
  require GpioInOut

  def init(gpio_name, gpio_no, on_delay, off_delay) do
    Logger.debug("#{__MODULE__}: led_blink #{gpio_name} #{gpio_no} start...")
    GpioInOut.start_link(gpio_name, gpio_no, :output)
    loop(gpio_name, on_delay, off_delay)
  end

  defp loop(gpio_name, on_delay, off_delay) do
    Logger.debug("#{__MODULE__}: led_blink #{gpio_name} on...")
    GpioInOut.write(gpio_name, 1)
    Process.sleep(on_delay)
    Logger.debug("#{__MODULE__}: led_blink #{gpio_name} off...")
    GpioInOut.write(gpio_name, 0)
    Process.sleep(off_delay)
    loop(gpio_name, on_delay, off_delay)
  end

  def stop(gpio_name) do
    Logger.debug("#{__MODULE__}: led_blink #{gpio_name} stop...")
    GpioInOut.stop(gpio_name)
  end

end
