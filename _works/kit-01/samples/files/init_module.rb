#
# WiFiモジュールの初期化、APを指定して接続開始
#
# * 購入後、一度だけ実行します（次回起動時は、この工程はスキップできます）
# * 設定は、WiFIモジュール内に保存されます。
#

SSID = "SSID"
PASS = "password"

sleep 3
puts "Program START"

$wifi = DA16200.new(UART.new(baudrate:115200))

#
# 初期化とAPへの接続
#
$wifi.debug_print = true
$wifi.initial_setup()
$wifi.connect_ap( SSID, PASS )
puts "Connected SSID: #{$wifi.connected_ssid}"
$wifi.set_sntp()
$wifi.debug_print = false

while true
  puts "="*40
  sleep 10

  $wifi.stat.each {|k,v|
    puts "#{k}: #{v}"
  }
end
