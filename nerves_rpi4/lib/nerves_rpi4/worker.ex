defmodule NervesRpi4.Worker do
  require Logger
##  require LedBlink
##  require I2cPCA9685
#  require Pwm
  use GenServer

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state = [:led]) do
    Logger.debug("#{__MODULE__}: genserver led blink start...")
    Task.async(fn -> LedBlink.init(:gpio_16, 16, 1000, 1000) end)
    Task.async(fn -> LedBlink.init(:gpio_17, 17, 400, 600) end)
    {:ok, state}
  end

  def init([:ledV2] = state) do
    Logger.debug("#{__MODULE__}: genserver led blink start...")
    Task.async(fn -> LedBlinkV2.init(:led_no0, :gpio_16, 16, 1000, 1000) end)
    Task.async(fn -> LedBlinkV2.init(:led_no1, :gpio_17, 17, 400, 600) end)
    {:ok, state}
  end

  def init([:m5env3V2] = state) do
    Logger.debug("#{__MODULE__}: m5env3V2 start...")
    Task.async(fn -> M5Env3V2.init(:sonsor_no1, :m5env3_no1, "i2c-1", 0x44) end)
    Task.async(fn -> LedBlinkV2.init(:led_no1, :gpio_16, 16, 400, 600) end)
    {:ok, state}
  end

  def init([:m5env2V2] = state) do
    Logger.debug("#{__MODULE__}: m5env2V2 start...")
    Task.async(fn -> M5Env2V2.init(:sonsor_no0, :m5env2_no0, "i2c-1", 0x44) end)
    Task.async(fn -> LedBlinkV2.init(:led_no1, :gpio_17, 17, 400, 600) end)
    {:ok, state}
  end

  def init([:button_not] = state) do
    Logger.debug("#{__MODULE__}: single led by one button start...")
    ButtonLed.button_not(:button, 12, :led, 16, 100)
    {:ok, state}
  end

  def init([:button_not_not] = state) do
    Logger.debug("#{__MODULE__}: double leds by one button start...")
    ButtonLed.button_not_not(:button, 12, :led0, 16, :led1, 17, 50)
    {:ok, state}
  end

  def init([:button_oneshot] = state) do
    Logger.debug("#{__MODULE__}: one shot led by one button start...")
    Task.async(fn -> LedBlinkV2.init(:led_no0, :gpio_16, 16, 50, 200) end)
    Task.async(fn -> ButtonLed.button_oneshot(:button, 12, :led, 17, 1000) end)
#    Task.async(fn -> ButtonLed.button_oneshot(:button, 12, :led, 17, 10000, 1000) end) # デバッグ用
    {:ok, state}
  end

  def init([:button_oneshot_reset] = state) do
    Logger.debug("#{__MODULE__}: one shot led by one button start...")
    Task.async(fn -> ButtonLed.button_oneshot_reset(:button_on, 12, :button_off, 13, :led, 17, 2500) end)
    {:ok, state}
  end

  def init([:logicled] = state) do
    Logger.debug("#{__MODULE__}: Logical AND start...")
    GpioInOut.start_link(:button_a, 12, :input)
    GpioInOut.start_link(:button_b, 13, :input)

    GpioInOut.start_link(:led_y, 17, :output)
    Task.async(fn -> LogicLed.logical_and(:button_a, :button_b, :led_x) end)
    Task.async(fn -> LogicLed.logical_or(:button_a, :button_b, :led_y) end)
    {:ok, state}
  end

  def init([:led1] = state) do
    Logger.debug("#{__MODULE__}: single led blink start...")
    LedBlink.init(:led_no0, 16, 1000, 1000)
    {:ok, state}
  end

  def init(state) do # Application.children/1 の引数を間違うとここに来る
    Logger.debug("#{__MODULE__}: No such operation defined!! state: #{inspect(state)}")
    {:error, state}
  end

#  defp pickup_middle4(bs), do: pickup_middle(bs, 12, 4, 8) # MCP3208
#  defp pickup_middle4(bs), do: pickup_middle(bs, 14, 4, 6) # MCP3008

#  defp pickup_middle(bs, l, m, n) do
#    <<_::size(l), mid_bs::size(m), _::size(n)>> = bs
#    mid_bs
#  end
end
