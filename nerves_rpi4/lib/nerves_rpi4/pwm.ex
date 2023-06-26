defmodule Pwm do
  require Logger
  require GpioInOut
  require SpiInOut

#  def init(spi_name, inst, interval \\ 50) do
#    Logger.debug("#{__MODULE__}: Read register start...")
#    SpiInOut.start_link(:spi0, "spidev0.0")
#    Process.sleep(100)
#
#    read_reg(spi_name, inst, interval)
#  end

  def read_reg(spi_name, inst, interval \\ 50) do
    {:ok, val} = SpiInOut.send_receive(spi_name, inst)
#    <<_::size(12), valbit::size(12)>> = val # MCP3208
    <<_::size(14), valbit::size(10)>> = val # MP3008
    Logger.debug("#{__MODULE__} #{spi_name}: #{inspect(valbit)} #{0..div(valbit,64) |> Enum.map(fn _n -> "=" end)}")
    Process.sleep(interval)
    read_reg(spi_name, inst, interval)
  end

  def potentio_led(spi_name, spi_inst, spi_pickup, led_name, interval \\ 50) do
    {:ok, rec_bs} = SpiInOut.send_receive(spi_name, spi_inst)
    upper4bit = spi_pickup.(rec_bs)
    on_time  = div(upper4bit * interval, 15)
    off_time = div((15 - upper4bit) * interval, 15)
    Logger.debug("#{__MODULE__} #{spi_name}: #{on_time}-#{off_time} #{0..upper4bit |> Enum.map(fn _n -> "=" end)}")
    GpioInOut.write(led_name, :true)
    Process.sleep(on_time)
    GpioInOut.write(led_name, :false)
    Process.sleep(off_time)
    potentio_led(spi_name, spi_inst, spi_pickup, led_name, interval)
  end
end
