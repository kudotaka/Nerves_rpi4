defmodule Libqmp6988 do
  use GenServer
  require I2cInOut
  require Logger
  import Bitwise

  def start_link(opts \\ []) do
    name = opts[:name] || __MODULE__
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def measure(pid) do
    GenServer.call(pid, :measure)
  end

  def stop(name), do: GenServer.stop(name)

  @impl GenServer
  def init(opts \\ []) do
    i2c_name = opts[:i2c_name]
    i2c_bus = opts[:i2c_bus]
    i2c_addr = opts[:i2c_addr]
    Logger.debug("name: #{opts[:name]} i2c_name: #{opts[:i2c_name]} i2c_bus: #{opts[:i2c_bus]} i2c_addr: #{opts[:i2c_addr]}")
    I2cInOut.start_link(i2c_name, i2c_bus)
    Process.sleep(100)

    I2cInOut.isdevice(i2c_name, i2c_addr)
    |> handle_init(i2c_name, i2c_addr)

  end

  defp i64_val(val) do
    << x :: integer-signed-size(64) >> = <<val :: integer-signed-size(64)>>
    x
  end
  defp i32_val(val) do
    << x :: integer-signed-size(32) >> = <<val :: integer-signed-size(32)>>
    x
  end
  defp i16_val(val) do
    << x :: integer-signed-size(16) >> = <<val :: integer-signed-size(16)>>
    x
  end
  defp u32_val(val) do
    << x :: integer-unsigned-size(32) >> = <<val :: integer-unsigned-size(32)>>
    x
  end

  defp handle_init({:ok, true}, i2c_name, i2c_addr) do
    # softwareReset QMP6988_RESET_REG:0xE0
    I2cInOut.write(i2c_name, i2c_addr, <<0xE0, 0xe6>>)
    Process.sleep(50)
    I2cInOut.write(i2c_name, i2c_addr, <<0xE0, 0x00>>)

    # getCalibrationData QMP6988_CALIBRATION_DATA_START:0xA0
    {:ok, {:ok, <<c00,c01,c02,c03,c04,c05,c06,c07,c08,c09,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21,c22,c23,c24>>}} = I2cInOut.writeread(i2c_name, i2c_addr, <<0xA0>>, 25)
    coe_a0_tmp1 = i32_val(((c18<<<12) ||| (c19<<<4) ||| (c24 &&& 0x0F)) <<< 12)
    coe_a0 = i32_val(coe_a0_tmp1 >>> 12)
    coe_a1 = i16_val((c20<<<8) ||| (c21))
    coe_a2 = i16_val((c22<<<8) ||| (c23))
    coe_b00 = i32_val(((c00<<<12) ||| (c01<<<4) ||| ((c24 &&& 0xF0)>>>4)))
    coe_bt1 = i16_val((c02<<<8) ||| (c03))
    coe_bt2 = i16_val((c04<<<8) ||| (c05))
    coe_bp1 = i16_val((c06<<<8) ||| (c07))
    coe_b11 = i16_val((c08<<<8) ||| (c09))
    coe_bp2 = i16_val((c10<<<8) ||| (c11))
    coe_b12 = i16_val((c12<<<8) ||| (c13))
    coe_b21 = i16_val((c14<<<8) ||| (c15))
    coe_bp3 = i16_val((c16<<<8) ||| (c17))
#    Logger.debug("coe_a0: #{coe_a0}  coe_a1: #{coe_a1}  coe_a2: #{coe_a2}  coe_b00: #{coe_b00}")
#    Logger.debug("coe_bt1: #{coe_bt1}  coe_bt2: #{coe_bt2}  coe_bp1: #{coe_bp1}  coe_b11: #{coe_b11}")
#    Logger.debug("coe_bp2: #{coe_bp2}  coe_b12: #{coe_b12}  coe_b21: #{coe_b21}  coe_bp3: #{coe_bp3}")

    ik_a0 = coe_a0
    ik_b00 = coe_b00
    ik_a1 = i32_val(3608 * coe_a1 - 1731677965)
    ik_a2 = i32_val(16889 * coe_a2 - 87619360)
    ik_bt1 = i64_val(2982 * coe_bt1 + 107370906)
    ik_bt2 = i64_val(329854 * coe_bt2 + 108083093)
    ik_bp1 = i64_val(19923 * coe_bp1 + 1133836764)
    ik_b11 = i64_val(2406 * coe_b11 + 118215883)
    ik_bp2 = i64_val(3079 * coe_bp2 - 181579595)
    ik_b12 = i64_val(6846 * coe_b12 + 85590281)
    ik_b21 = i64_val(13836 * coe_b21 + 79333336)
    ik_bp3 = i64_val(2915 * coe_bp3 + 157155561)
#    Logger.debug("ik_a0: #{ik_a0}  ik_a1: #{ik_a1}  ik_a2: #{ik_a2}  ik_b00: #{ik_b00}")
#    Logger.debug("ik_bt1: #{ik_bt1}  ik_bt2: #{ik_bt2}  ik_bp1: #{ik_bp1}  ik_b11: #{ik_b11}")
#    Logger.debug("ik_bp2: #{ik_bp2}  ik_b12: #{ik_b12}  ik_b21: #{ik_b21}  ik_bp3: #{ik_bp3}")

    # setpPowermode QMP6988_CTRLMEAS_REG:0xF4
    {:ok, {:ok, <<datatmp0>>}} = I2cInOut.writeread(i2c_name, i2c_addr, <<0xF4>>, 1)
    datatmp1 = (datatmp0 &&& 0xFC)
    powermode = (datatmp1 ||| 0x03)
    I2cInOut.write(i2c_name, i2c_addr, <<0xF4, powermode>>)

    # setFilter QMP6988_CONFIG_REG:0xF1
    filter = (0x02 &&& 0x03)
    I2cInOut.write(i2c_name, i2c_addr, <<0xF1, filter>>)

    # setOversamplingP QMP6988_CTRLMEAS_REG:0xF4
    {:ok, {:ok, <<datap0>>}} = I2cInOut.writeread(i2c_name, i2c_addr, <<0xF4>>, 1)
    datap1 = (datap0 &&& 0xE3)
    datap2 = datap1 ||| (0x04<<<2)
    I2cInOut.write(i2c_name, i2c_addr, <<0xF4, datap2>>)

    # setOversamplingT
    {:ok, {:ok, <<datat0>>}} = I2cInOut.writeread(i2c_name, i2c_addr, <<0xF4>>, 1)
    datat1 = (datat0 &&& 0x1F)
    datat2 = datat1 ||| (0x01<<<5)
    I2cInOut.write(i2c_name, i2c_addr, <<0xF4, datat2>>)

    Process.sleep(100)
    {:ok, %{i2c_name: i2c_name, i2c_addr: i2c_addr, ik_a0: ik_a0, ik_a1: ik_a1, ik_a2: ik_a2, ik_b00: ik_b00, ik_bt1: ik_bt1, ik_bt2: ik_bt2, ik_bp1: ik_bp1, ik_b11: ik_b11, ik_bp2: ik_bp2, ik_b12: ik_b12, ik_b21: ik_b21, ik_bp3: ik_bp3}}
  end
  defp handle_init({_, false}, i2c_name, i2c_addr) do
    {:error, %{i2c_name: i2c_name, i2c_addr: i2c_addr, reason: "device not found. #{i2c_name} #{i2c_addr}"}}
  end

  @impl GenServer
  def handle_call(:measure, _from, state) do
    {:reply, measure_sensor(state), state}
  end

  defp measure_sensor(state) do
    I2cInOut.write(state.i2c_name, state.i2c_addr, <<0xF7>>)
    Process.sleep(100)
    I2cInOut.read(state.i2c_name, state.i2c_addr, 6)
    |> handle_data(state)

  end

  defp handle_data({:ok, {:ok, rawdata}}, state) do
    #バイト分割
    <<p0, p1, p2, t3, t4, t5>> = rawdata
    p_read = u32_val((p0<<<16) ||| (p1<<<8) ||| (p2))
    p_raw = i32_val(p_read - 8388608) # SUBTRACTOR
    t_read = u32_val((t3<<<16) ||| (t4<<<8) ||| (t5))
    t_raw = i32_val(t_read - 8388608) # SUBTRACTOR

    # convTx02e()
    ik_a1 = state.ik_a1
    ik_a2 = state.ik_a2
    ik_a0 = state.ik_a0
    wkt1 = i64_val(ik_a1 * t_raw)
    wkt2_1 = i64_val((ik_a2 * t_raw) >>> 14)
    wkt2_2 = i64_val((wkt2_1 * t_raw) >>> 10)
    wkt2 = i64_val((div((wkt1 + wkt2_2),32767)) >>> 19)
    t_int = i16_val((ik_a0 + wkt2) >>> 4)

    # getPressure02e
    ik_bt1 = state.ik_bt1
    ik_bt2 = state.ik_bt2
    ik_bp1 = state.ik_bp1
    ik_bp2 = state.ik_bp2
    ik_bp3 = state.ik_bp3
    ik_b11 = state.ik_b11
    ik_b12 = state.ik_b12
    ik_b21 = state.ik_b21
    ik_b00 = state.ik_b00
    wkp1_1 = i64_val(ik_bt1 * t_int)
    wkp2_1 = i64_val((ik_bp1 * p_raw) >>> 5)
    wkp1_2 = i64_val(wkp1_1 + wkp2_1)
    wkp2_2 = i64_val((ik_bt2 * t_int) >>> 1)
    wkp2_3 = i64_val((wkp2_2 * t_int) >>> 8)
    wkp3_1 = wkp2_3
    wkp2_4 = i64_val((ik_b11 * t_int) >>> 4)
    wkp2_5 = i64_val((wkp2_4 * p_raw) >>> 1)
    wkp3_2 = i64_val(wkp3_1 + wkp2_5)
    wkp2_6 = i64_val((ik_bp2 * p_raw) >>> 13)
    wkp2_7 = i64_val((wkp2_6 * p_raw) >>> 1)
    wkp3_3 = i64_val(wkp3_2 + wkp2_7)
    wkp1_3 = i64_val(wkp1_2 + i64_val(wkp3_3 >>> 14))
    wkp2_8 = i64_val(ik_b12 * t_int)
    wkp2_9 = i64_val((wkp2_8 * t_int) >>> 22)
    wkp2_10 = i64_val((wkp2_9 * p_raw) >>> 1)
    wkp3_4 = wkp2_10
    wkp2_11 = i64_val((ik_b21 * t_int) >>> 6)
    wkp2_12 = i64_val((wkp2_11 * p_raw) >>> 23)
    wkp2_13 = i64_val((wkp2_12 * p_raw) >>> 1)
    wkp3_5 = i64_val(wkp3_4 + wkp2_13)
    wkp2_14 = i64_val((ik_bp3 * p_raw) >>> 12)
    wkp2_15 = i64_val((wkp2_14 * p_raw) >>> 23)
    wkp2_16 = i64_val(wkp2_15 * p_raw)
    wkp3_6 = i64_val(wkp3_5 + wkp2_16)
    wkp1_4 = i64_val(wkp1_3 + i64_val(wkp3_6 >>> 15))
    wkp1_5 = i64_val(div(wkp1_4,32767))
    wkp1_6 = i64_val(wkp1_5 >>> 11)
    p_int = i32_val(wkp1_6 + ik_b00)

    # qmp6988.temperature (degree Celsius)
    temp = (t_int / 256.0)

    # qmp6988.pressure (hPa)
    press = ((p_int / 16.0) / 100.0)

    {:ok, %{pressure: press, temperature: temp}}
  end

  defp handle_data({:ok, {:error, reason}}, _state) do
    Logger.debug("handle_data: #{reason}")
    {:error, reason}
  end

  defp handle_data(_, state) do
    Process.sleep(500)
    measure_sensor(state)
  end

  @impl GenServer
  def terminate(reason, {i2c_name}) do
    Logger.debug("#{__MODULE__} terminate: #{inspect(reason)}")
    I2cInOut.stop(i2c_name)
#    Circuits.I2C.close(i2cref)
    reason
  end

end
