defmodule LogicLed do
  require Logger
  require GpioInOut

  def logical_any(button_a_name, button_b_name, led_name, ope, interval \\ 50) do
    {:ok, a} = GpioInOut.read(button_a_name)
    {:ok, b} = GpioInOut.read(button_b_name)
    GpioInOut.write(led_name, ope.(to_nboolean(a), to_nboolean(b)))
    Process.sleep(interval)
    logical_any(button_a_name, button_b_name, led_name, ope, interval)
  end

  def logical_and(button_a_name, button_b_name, led_name, interval \\ 50) do
    logical_any(button_a_name, button_b_name, led_name, &and/2, interval)
  end

  def logical_or(button_a_name, button_b_name, led_name, interval \\ 50) do
    logical_any(button_a_name, button_b_name, led_name, &or/2, interval)
  end

  defp to_nboolean(0), do: :true
  defp to_nboolean(_), do: :false
end
