defmodule ButtonLed do
  require Logger
  require GpioInOut

  def button_not(button_name, button_no, led_name, led_no, interval) do
    Logger.debug("#{__MODULE__}: button_led #{button_name} #{button_no} #{led_name} #{led_no} #{interval} start...")
    GpioInOut.start_link(button_name, button_no, :input)
    GpioInOut.start_link(led_name, led_no, :output)
    not_loop(button_name, led_name, interval)
  end

  defp not_loop(button_name, led_name, interval) do
    {:ok, val} = GpioInOut.read(button_name)
    GpioInOut.write(led_name, val)
    Logger.debug("#{__MODULE__}, button = #{val}")
    Process.sleep(interval)
    not_loop(button_name, led_name, interval)
  end

  def button_not_not(button_name, button_no, led0_name, led0_no, led1_name, led1_no, interval) do
    GpioInOut.start_link(button_name, button_no, :input)
    GpioInOut.start_link(led0_name, led0_no, :output)
    GpioInOut.start_link(led1_name, led1_no, :output)
    not_not_loop(button_name, led0_name, led1_name, interval)
  end

  defp not_not_loop(button_name, led0_name, led1_name, interval) do
    {:ok, val} = GpioInOut.read(button_name)
    GpioInOut.write(led0_name, val)
    GpioInOut.write(led1_name, 1-val)
    Logger.debug("#{__MODULE__}, button = #{val}")
    Process.sleep(interval)
    not_not_loop(button_name, led0_name, led1_name, interval)
  end

  def button_oneshot(button_name, button_no, led_name, led_no, delay, interval \\ 50) do
    GpioInOut.start_link(button_name, button_no, :input)
    GpioInOut.start_link(led_name, led_no, :output)
    oneshot_loop(button_name, led_name, div(delay, interval), interval)
  end

  defp oneshot_loop(button_name, led_name, count, interval, prev \\ 1, timer \\ 0) do
#    Logger.debug("#{__MODULE__}, #{count}, #{prev}, #{timer}")
#    Logger.debug("#{0..timer |> Enum.map(&(to_string(rem(&1,10))))}")
    Logger.debug("#{0..timer |> Enum.map(fn _n -> "*" end)}")
    {:ok, now} = GpioInOut.read(button_name)
    timer = if (now == 0) and (prev == 1), do: count, else: timer
    timer = if (timer > 0), do: timer - 1, else: 0
    GpioInOut.write(led_name, (if (timer > 0), do: 1, else: 0))
    Process.sleep(interval)
    oneshot_loop(button_name, led_name, count, interval, now, timer)
  end

  def button_oneshot_reset(button_on_name, button_on_no, button_off_name, button_off_no, led_name, led_no, delay, interval \\ 50) do
    GpioInOut.start_link(button_on_name, button_on_no, :input)
    GpioInOut.start_link(button_off_name, button_off_no, :input)
    GpioInOut.start_link(led_name, led_no, :output)
    oneshot_loop_reset(button_on_name, button_off_name, led_name, div(delay, interval), interval)
  end

  defp oneshot_loop_reset(button_on_name, button_off_name, led_name, count, interval, prev \\ 1, timer \\ 0) do
    {:ok, now} = GpioInOut.read(button_on_name)
    {:ok, reset} = GpioInOut.read(button_off_name)
#    Logger.debug("#{__MODULE__}, #{count}, #{prev}, #{timer}")
#    Logger.debug("#{__MODULE__}, #{now}, #{prev}, #{reset}, #{timer}")
    Logger.debug("#{0..timer |> Enum.map(fn _n -> "*" end)}")
    timer = if (now == 0) and (prev == 1), do: count, else: timer
    timer = if (timer > 0) and (reset == 1), do: timer - 1, else: 0
    GpioInOut.write(led_name, (if (timer > 0), do: 1, else: 0))
    Process.sleep(interval)
    oneshot_loop_reset(button_on_name, button_off_name, led_name, count, interval, now, timer)
  end
end
