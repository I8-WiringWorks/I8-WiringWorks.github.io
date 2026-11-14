#!/usr/bin/env ruby
#
# HTTP GET および POST のサンプル
#
# * WiFi AP に接続が完了していること。
#

sleep 3
puts "Program START"

$wifi = DA16200.new(UART.new(baudrate:115200))
#$wifi.debug_print = true

# Waiting for AP connection.
$wifi.sync()
while !$wifi.stat["all_ok"]
  puts "Waiting for AP connection."
  $wifi.reconnect_ap()
  sleep 10
end


#
# HTTP GET test
#
# param=value 形式のデータを付加してGETプロトコルでアクセスするサンプル
#
puts "========== HTTP GET TEST =========="

url = "https://httpbin.org/get"
param = "param1=111&param2=222"
res = $wifi.http_get(url + "?" + param)

res.each {|k,v|
  puts "\n==== #{k} ===="
  puts v
}

# 連続してDA16200にアクセスを依頼すると、モジュール内部でのクリーンアップ処理が
# 追いつかない場合があるので、ウェイトをかける。
sleep 1

#
# HTTP POST test
#
# JSONデータのPOST
#
puts "\n\n========== HTTP POST TEST =========="

url = "https://httpbin.org/post"
postdata = '{"key1":"ABCD", "key2":1234}'
res = $wifi.http_post( url, postdata,
                       http_headers:{"Content-Type"=>"application/json"} )
res.each {|k,v|
  puts "\n==== #{k} ===="
  puts v
}
