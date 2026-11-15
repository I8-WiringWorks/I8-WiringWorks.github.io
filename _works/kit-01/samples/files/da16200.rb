##
# Renesas DA16200 Wi-Fi module control class
#
# (Usage)
# AP Setup.
#  wifi = DA16200.new( UART.new("/dev/serial0", baudrate:115200))
#  wifi.initial_setup()
#  wifi.connect_ap( "SSID", "KEY", hidden:[true|false] )
#  pp wifi.stat
#
# Updated: 2026/11/15 14:35:02


class DA16200
  attr_reader :connected
  attr_reader :connected_ssid
  attr_accessor :debug_print

  ##
  # constructor
  #
  #@param  [IODevice] io_device   IO device object (e.g. UART)
  #
  def initialize( io_device )
    @dev = io_device
    @connected = nil
    @debug_print = false
  end


  ##
  # Debug print
  #
  #@param  [String] msg         Print format string
  #@param  [Array]  arg         Print format arguments
  #
  def dp( msg, *arg )
    return if !@debug_print
    printf( msg, *arg )
  end


  ##
  # Read line with timeout.
  #
  #@param  [Float] timeout      Timeout seconds
  #@return [String]             Read line string
  #@raise  [IOError]            If timeout
  #
  def gets_with_timeout( timeout = 5 )
    (timeout * 10).to_i.times {
      if @dev.can_read_line()
        s = @dev.gets
        dp("<--- %s", s)
        return s
      end
      sleep_ms 100
    }

    raise IOError, "Timeout"
  end


  ##
  # Read specified bytes with timeout.
  #
  #@param  [Integer] bytes_to_read  Number of bytes to read
  #@param  [Float]   timeout        Timeout seconds
  #@param  [String]  append         String to append to the read data
  #@return [String]                 Read data
  #@raise  [IOError]                If timeout
  #
  def read_with_timeout( bytes_to_read, timeout = 5, append: nil )
    ret = append || ""
    avail = nil
    total_bytes = 0

    while total_bytes < bytes_to_read
      (timeout * 10).to_i.times {
        avail = @dev.bytes_available()
        break if avail != 0
        sleep_ms 100
      }
      raise IOError, "Timeout"  if avail == 0

      remain = bytes_to_read - total_bytes
      to_read = (avail < remain) ? avail : remain
      ret << @dev.read( to_read )
      total_bytes += to_read
    end

    dp("<--- (read %d bytes)\n", total_bytes)
    return ret
  end


  ##
  # Send AT command and get response.
  #
  #@param  [String] cmd         AT command string (without "AT+")
  #@param  [String] expected    Expected response string (e.g. "+WFSTAT:")
  #@return [String]             Response string or "ERROR:..."
  #@raise  [IOError]            If timeout
  #
  def atcmd( cmd, expected = nil )
    # clear unused responses, if exist.
    avail = @dev.bytes_available()
    @dev.read( avail )  if avail > 0

    # send command
    @dev.write("\r\nAT+#{cmd}\r\n")
    dp("===> AT+%s\n", cmd)

    # receive response
    while true
      ret = ""

      # omit 1st CRLF
      s = gets_with_timeout()
      next if s == "\r\n"

      # receive until "OK" or "ERROR"
      while true
        break  if s == "OK\r\n"
        ret << s
        return ret  if s.start_with?("ERROR:")
        s = gets_with_timeout()
      end

      # expected response?
      break  if !expected || ret.start_with?(expected)
    end

    return ret
  end


  ##
  # sync connection
  #
  #@param  [Integer] n_try      Number of retry times
  #@return [Bool]               true: success, false: failed
  #
  def sync( n_try = 20 )
    ex = nil
    @dev.clear_rx_buffer()

    # AT -> OK -> timeout
    n_try.times {
      @dev.write("AT\r\n")
      dp("===> AT\n")
      flag_ok = nil

      while true
        begin
          s = gets_with_timeout(1).chomp
          if !s.empty? && flag_ok == nil
            flag_ok = (s == "OK")
          end
        rescue =>ex
          break
        end
      end

      return true  if flag_ok
    }

    return false
  end


  ##
  # Module initial setup.
  #
  #@param  [String] country      Country code (JP, US, EU, ...)
  #@param  [Integer] tzone       Timezone offset seconds (e.g. 32400 for JST)
  #
  def initial_setup( country = "JP", tzone = 32400 )
    @dev.write("\r\nATF\r\n")
    dp("===> ATF\n")

    until gets_with_timeout().start_with?("+INIT:DONE")
      sleep_ms 100
    end

    atcmd("WFMODE=0")   # Set station mode
    restart()           # send "AT+RESTART"

    # 国設定
    atcmd("WFCC=#{country}")
    atcmd("TZONE=#{tzone}")
  end


  ##
  # module restart
  #
  #@raise  [IOError]            If failed to restart
  #
  def restart()
    atcmd("RESTART")
    until gets_with_timeout().start_with?("+INIT:DONE")
      sleep_ms 100
    end
  end


  ##
  # Connect to Wi-Fi access point.
  #
  #@param  [String] ssid        SSID
  #@param  [String] key         Security key (WPA2-PSK
  #@param  [Bool]   hidden      Flag for hidden SSID
  #@return [Integer]            Connection result code (+WFJAP:n, ...)
  #                             (0:failed, 1:connected, 2:disconnected)
  #
  # TODO: WPA2以外のアクセスポイントに、接続できるのか確認が必要。
  #
  def connect_ap( ssid, key, hidden:false )
    cmd = "WFJAPA='#{ssid}'"
    cmd << ",'#{key}'"  if key
    cmd << ",1"         if hidden

    _sub_connect_ap(cmd)
  end

  def _sub_connect_ap( cmd )
    if atcmd(cmd).start_with?("ERROR:")
      return 0
    end

    s = nil
    3.times {
      s = gets_with_timeout(60)
      break if !s.chomp.empty?
    }

    # WFJAPAコマンドの送信後は、接続完了もしくはTimeoutまで他のコマンドを
    # 受け付けないので、ここで自動的に送られてくるWiFI接続ステータスを待つ。
    # (see: Table 12. Wi-Fi function response list)
    if s.start_with?("+WFJAP:")
      a = s.split(",")
      result_code = a[0][-1].to_i       # 0:failed, 1:success
    elsif s.start_with?("+WFDAP:")
      a = s.split(",")
      result_code = 2                   # 2:disconnected
    else
      raise IOError, "AP Connection Error"
    end

    @connected = (result_code == 1)
    @connected_ssid = a[1].chomp
    if @connected_ssid[0] == "'"
      @connected_ssid[0] = @connected_ssid[-1] = ""
    end

    return result_code
  end


  ##
  # Re-connect to Wi-Fi access point with saved ssid and password.
  #
  #@return [Integer]            Connection result code (+WFJAP:n, ...)
  #                             (0:failed, 1:connected, 2:disconnected)
  def reconnect_ap()
    atcmd("WFQAP")
    sleep 1

    _sub_connect_ap("WFCAP")
  end


  ##
  # Get Wi-Fi connection status.
  #
  #@return [Hash]       Wi-Fi connection status.
  #@raise  [IOError]    If failed to get status
  #
  def stat()
    ret = {}
    res = atcmd("WFSTAT", "+WFSTAT:")
    res.split("\n").each {|line|
      k,v = line.split("=", 2)
      ret[k] = v  if v
    }
    @connected = false
    @connected_ssid = ret["ssid"]
    return ret if ret["wpa_state"] != "COMPLETED"

    dmy,ip,mask,gw = atcmd("NWIP=?", "+NWIP:").split(",")
    ret["ipv4"] = ip
    ret["ipv4_mask"] = mask
    ret["ipv4_gw"] = gw

    if ip != "0.0.0.0"
      res = atcmd("NWDNS=?", "+NWDNS:")
      if res.start_with?("+NWDNS:")
        ret["dns"] = res.split(":")[1]
      end
    end

    @connected = (ret["wpa_state"] == "COMPLETED" &&
                  ip != "0.0.0.0" &&
                  ret["dns"] != nil)
    ret["all_ok"] = @connected
    return ret
  end


  ##
  # Scan Wi-Fi access points.
  #
  #@return [Array<Hash>]   Scanned access points information array.
  #
  # (example)
  # wifi.scan.each {|ap| a = ap.values
  #   print "#{a[0]}\t#{a[1]}\t#{a[2]}\t#{a[4]}\t"
  #   print "\t" if a[4].size < 8
  #   print "#{a[3].join(',')}\n"
  # }
  #
  def scan()
    res = atcmd("WFSCAN", "+WFSCAN:")
    if !res.start_with?("+WFSCAN:")
      raise IOError, "Illegal response " + "+WFSCAN:" + res.to_s.chomp
    end

    aps = res.split("\n")
    aps[0] = aps[0][8,100]  if aps[0]

    ret = []
    aps.each {|ap|
      a = ap.split("\t")
      next if a.size < 5
      ret << { bssid:a[0], frequency:a[1], signal_strength:a[2],
               flag:a[3][1, a[3].size-2].to_s.split("]["), ssid:a[4] }
    }

    return ret
  end


  ##
  # Get current date and time string.
  #
  #@return [String]   DateTime string in "YYYY-MM-DD,hh:mm:ss±zz" format.
  #                     (±zz: timezone offset hours)
  #@raise  [IOError]  If failed to get time
  #
  # (note)
  #  時刻同期していなければ、UNIX epoch timeからの経過時間が返される。
  #
  def time()
    s = atcmd("TIME=?", "+TIME:")
    if !s.start_with?("+TIME:")
      raise IOError, "Illegal response " + "+TIME:" + s.to_s.chomp
    end
    datetime = s[6,19]

    s = atcmd("TZONE=?", "+TZONE:")
    if !s.start_with?("+TZONE:")
      raise IOError, "Illegal response " + "+TZONE:" + s.to_s.chomp
    end

    return sprintf("%s%+03d", datetime, s[7,100].to_i / 3600)
  end


  ##
  # Set SNTP server and update period.
  #
  #@param  [String] server      SNTP server hostname or IP address
  #@param  [Integer] period     Update period in seconds
  #@raise  [IOError]            If failed to set SNTP
  #
  def set_sntp( server = "pool.ntp.org", period = 86400 )
    atcmd("NWSNTP=1,#{server},#{period}")
  end


  ##
  #
  # HTTP GET command.
  #
  #@param  [String]  url        URL string
  #@param  [Bool]    header     Flag to get HTTP headers
  #@param  [Bool]    body       Flag to get HTTP body
  #@param  [Integer] limit      Size limit guideline
  #@return [Hash]               Result hash
  #                               {:cmd_status=> , :http_status=> ,
  #                                :headers=> , :body=> }
  #
  def http_get( url, header:true, body:true, limit:nil )
    # send http access command
    res = atcmd("NWHTCH=#{url},get")
    if res.start_with?("ERROR:")
      return { cmd_status: res[6,100].to_i }
    end

    begin
      ret = _http_receive_data( header, body, limit )
    rescue IOError=>ex
      ret = { cmd_status: 105, error: ex.message }
    end

    return ret
  end

  def _http_receive_data( flag_header, flag_body, limit )
    cmd_status = http_status = headers = nil
    data = ""

    # receive
    s = gets_with_timeout(30)
    while true
      if s.start_with?("+NWHTCDATA:")
        cdata,remain = s.split(",", 2)
        size = cdata[11, 100].to_i

        if !http_status
          # 最初のデータは、HTTP ステータスであり、改行で終わる。
          # size-remain.size 分は追加で読む必要あり
          http_status = remain
          size -= http_status.size
          remain = ""
        end

        if size < remain.size
          # gets で読み過ぎていたら、remainからその分取得し、REDOする。
          s = remain.slice!(0, size)
          data << s  if !limit || data.size < limit
          s = remain
          next
        end

        if !limit || data.size < limit
          data << remain
          read_with_timeout(size - remain.size, append: data)
        else
          read_with_timeout(size - remain.size)
        end

      elsif s.start_with?("+NWHTCSTATUS:")  # see: UM-WI-003 Appendix B
        cmd_status = s[13,100].to_i
        break
      end

      s = gets_with_timeout()
    end
    s = cdata = remain = nil    # release memory

    # check HTTP status code.
    if http_status
      if !http_status.start_with?("HTTP/")
        raise IOError, "Illegal HTTP response. '#{http_status}'"
      end
      http_status = http_status[9,3].to_i
    end

    # convert http headers to hash
    headers = {}
    flag_chunked = false
    start = 0
    while idx = data.index("\n", start)
      line = data[start, idx - start + 1].chomp
      break if line.empty?
      tag, content = line.split(":", 2)
      content&.strip!
      headers[tag] = content  if flag_header
      flag_chunked = true  if tag == "Transfer-Encoding" && content == "chunked"
      start = idx + 1
    end

    # Keep only the response body
    if flag_body
      idx = data.size if !idx
      data[0, idx+1] = ""
    else
      data.clear
    end

    # decode chunked body
    if flag_chunked
      cursor = 0
      while true
        idx = data.index("\n", cursor == 0 ? 0 : cursor + 2)
        break if !idx
        chunk_size = data.slice!(cursor, idx - cursor + 1).strip.to_i(16)
        break if chunk_size == 0
        cursor += chunk_size
      end

      remain = data.size - cursor
      data.slice!(cursor, remain) if remain > 0
    end

    # build return value.
    ret = { cmd_status: cmd_status,
            http_status: http_status,
            headers: headers,
            body: data }
    return ret
  end


  ##
  # HTTP POST command.
  #
  #@param  [String]  url          URL string
  #@param  [String]  postdata     POST data string
  #@param  [Bool]    header       Flag to get HTTP headers
  #@param  [Bool]    body         Flag to get HTTP body
  #@param  [Hash]    http_headers Additional HTTP headers hash
  #@param  [Integer] limit        Size limit guideline
  #@return [Hash]                 Result hash
  #                               {:cmd_status=> , :http_status=> ,
  #                                :headers=> , :body=> }
  #(note)
  # http_headers example: {"Content-Type"=>"application/json"}
  # モジュールのATコマンドライン制限により、送ることができないバイト列が
  # あるかもしれない。特に、改行コードを含むコントロールコードや
  # シングルクォート、ダブルクォートの混在は十分にテストがなされていない。
  #
  # (example)
  # postdata = '{"key1":"ABCD", "key2":1234}'
  # res = wifi.http_post( url, postdata, http_headers:{"Content-Type"=>"application/json"} )
  #
  def http_post( url, postdata, header:true, body:true, http_headers:{}, limit:nil )
    # parse URL
    if url.start_with?("http://")
      url_scheme = "http://"
    elsif url.start_with?("https://")
      url_scheme = "https://"
    else
      raise IOError, "Illegal scheme."
    end

    idx_host = url_scheme.size
    idx_path = url.index("/", idx_host) || url.index("?", idx_host)
    url_host = url[idx_host, (idx_path || url.size) - idx_host]

    if !idx_path
      url_path = "/"
    elsif url[idx_path] == "?"
      url_path = "/" + url[idx_path, url.size - idx_path]
    else
      url_path = url[idx_path, url.size - idx_path]
    end

    # prepare access command
    cmd = "NWHTCH=#{url_scheme}#{url_host},'POST #{url_path} HTTP/1.1\\r\\n"
    cmd << "Host: #{url_host}\\r\\n"
    http_headers.each {|k,v| cmd << "#{k}: #{v}\\r\\n" }
    cmd << "Content-Length: #{postdata.size}\\r\\n"
    cmd << "Connection: Close\\r\\n\\r\\n"
    idx = cmd.size
    cmd << postdata
    while idx = cmd.index("\r\n", idx)
      cmd[idx,2] = "\\r\\n"
      idx += 4
    end
    cmd << "\\r\\n'"

    # send http access command
    res = atcmd(cmd)
    if res.start_with?("ERROR:")
      return { cmd_status: res[6,100].to_i }
    end

    begin
      ret = _http_receive_data( header, body, limit )
    rescue IOError=>ex
      ret = { cmd_status: 105, error: ex.message }
    end

    return ret
  end

end # class DA16200
