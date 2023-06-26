defmodule LedBlinkV2 do
  require Logger
  require LibLedBlink

  def init(led_name, gpio_name, gpio_no, on_delay, off_delay) do
    Logger.debug("#{__MODULE__}: LedBlinkV2 #{led_name} start...")
    opts = [name: led_name, gpio_name: gpio_name, gpio_no: gpio_no,on_delay: on_delay,off_delay: off_delay]
    {:ok, pid} = LibLedBlink.start_link(opts)
    Process.sleep(100)
    opts = [pid: pid]
    loop(opts, pid)
#    loop(pid)
  end

  defp loop(led_name, pid) do
#  defp loop(pid) do
    LibLedBlink.led_blink(pid)
    loop(led_name, pid)
  end

  def stop(led_name) do
    Logger.debug("#{__MODULE__}: LedBlinkV2 #{led_name} stop...")
    LibLedBlink.stop(led_name)
  end
end
