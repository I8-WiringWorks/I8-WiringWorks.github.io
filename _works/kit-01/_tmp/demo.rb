require 'serialport'

# --- 設定項目 ---
PORT = '/dev/cu.usbmodem141201'
BAUD_RATE = 19200
DATA_BITS = 8
STOP_BITS = 1
PARITY = SerialPort::NONE

DEFAULT_DELAY_SEC = 0.1

# 送信関数: 指定した文字列を1文字ずつディレイを挟んで送信する
def send_with_delay(sp, text, delay_sec = DEFAULT_DELAY_SEC)
  text.each_char do |c|
    sp.write(c)
    sp.flush
    sleep(delay_sec)
  end
  sleep 0.5
  sp.write("\r\n")
end

begin
  sp = SerialPort.new(PORT, BAUD_RATE, DATA_BITS, STOP_BITS, PARITY)
  sp.read_timeout = 0 # データ到着までOSレベルで完全ブロッキング

  puts "Connected to #{PORT} @ #{BAUD_RATE}bps"
  puts "Press Ctrl+C to exit.\n\n"
  sleep 10

  # --- 受信スレッド（ブロッキング待機） ---
  rx_thread = Thread.new do
    loop do
      char = sp.getc
      break if char.nil?

      print char
      $stdout.flush
    end
  rescue IOError, SystemCallError
    # クローズ時の例外ハンドリング
  end

  # --- 送信部（関数の呼び出し例） ---
  send_with_delay(sp, "AT")
  sleep 1

  send_with_delay(sp, "AT+WFSCAN")
  sleep 2

  send_with_delay(sp, "AT+WFJAPA=SSID,password")
  sleep 5


  send_with_delay(sp, "AT+WFSTAT")
  sleep 1

  send_with_delay(sp, "AT+NWHTCH=http://httpbin.org/get,get")

  # 受信監視を継続
  rx_thread.join

rescue Interrupt
  puts "\nTerminating program..."
ensure
  send_with_delay(sp, "AT+WFQAP", 0.05)
  sleep 2
  rx_thread&.kill
  sp&.close unless sp&.closed?
  puts "Port closed."
end
