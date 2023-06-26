defmodule St7302lcd0802 do
  @behaviour GenServer
  require Logger

  def start_link(lcd_name, i2c_bus, i2c_addr, gpio_no) do
    GenServer.start_link(__MODULE__, {lcd_name, i2c_bus, i2c_addr, gpio_no}, name: lcd_name)
  end

  def puts(lcd_name, string) do
    GenServer.cast(lcd_name, {:puts, string})
  end

  def puts(lcd_name, string, row, column) do
    GenServer.cast(lcd_name, {:puts, string, row, column})
  end

  def clear(lcd_name) do
    GenServer.cast(lcd_name, :clear)
  end

  def backlight(lcd_name, on_off) do
    GenServer.cast(lcd_name, {:backlight, on_off})
  end

  def stop(lcd_name), do: GenServer.stop(lcd_name)

  @impl GenServer
  def init({lcd_name, i2c_bus, i2c_addr, gpio_no}) do
    i2c_name = to_string(lcd_name) <> ":i2c"   |> String.to_atom
    gpio_name = to_string(lcd_name) <> ":gpio" |> String.to_atom
    I2cInOut.start_link(i2c_name, i2c_bus)
    GpioInOut.start_link(gpio_name, gpio_no, :output)
    init_lcd(i2c_name, i2c_addr)
    {:ok, {i2c_name, i2c_addr, gpio_name}}
  end

  defp init_lcd(i2c_name, i2c_addr) do
    send_command(i2c_name, i2c_addr, 0x38)
    send_command(i2c_name, i2c_addr, 0x39)
    send_command(i2c_name, i2c_addr, 0x14)
    send_command(i2c_name, i2c_addr, 0x70)
    send_command(i2c_name, i2c_addr, 0x56)
    send_command(i2c_name, i2c_addr, 0x6c)
    Process.sleep(200)
    send_command(i2c_name, i2c_addr, 0x38)
    send_command(i2c_name, i2c_addr, 0x0c)
    send_command(i2c_name, i2c_addr, 0x01)
  end

  defp send_command(i2c_name, i2c_addr, bytedata) do
    I2cInOut.write(i2c_name, i2c_addr, <<0, bytedata>>)
    Process.sleep(1)
  end

  @impl GenServer
  def handle_cast({:backlight, on_off}, {i2c_name, i2c_addr, gpio_name}) do
    Logger.debug("#{__MODULE__} backlight: #{inspect(gpio_name)}")
    GpioInOut.write(gpio_name, on_off)
    {:noreply, {i2c_name, i2c_addr, gpio_name}}
  end

  @impl GenServer
  def handle_cast({:puts, string}, {i2c_name, i2c_addr, gpio_name}) do
    Logger.debug("#{__MODULE__} backlight: #{inspect(i2c_name)}, #{string}")
    to_charlist(string)
      |> Enum.map(fn c -> send_char(i2c_name, i2c_addr, c) end)
    {:noreply, {i2c_name, i2c_addr, gpio_name}}
  end

  @impl GenServer
  def handle_cast({:puts, string, x, y}, {i2c_name, i2c_addr, gpio_name}) do
    Logger.debug("#{__MODULE__} backlight: #{inspect(i2c_name)}, #{string}, #{x}, #{y}")
    send_command(i2c_name, i2c_addr, 0x80 + y * 0x40 + x)
    :binary.bin_to_list(string)
      |> Enum.map(fn c -> send_char(i2c_name, i2c_addr, c) end)
    {:noreply, {i2c_name, i2c_addr, gpio_name}}
  end

  @impl GenServer
  def handle_cast(:clear, {i2c_name, i2c_addr, gpio_name}) do
    send_command(i2c_name, i2c_addr, 0x01)
    {:noreply, {i2c_name, i2c_addr, gpio_name}}
  end

  defp send_char(i2c_name, i2c_addr, bytedata) do
    I2cInOut.write(i2c_name, i2c_addr, <<0x40, bytedata>>)
  end

  @impl GenServer
  def terminate(reason, {i2c_name, _i2c_addr, gpio_name}) do
    I2cInOut.stop(i2c_name)
    GpioInOut.stop(gpio_name)
    reason
  end
end
