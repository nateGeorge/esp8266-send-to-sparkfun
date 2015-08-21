-- ***************************************************************************
-- data.sparkfun posting module for ESP8266 with nodeMCU
--
-- Written by Nathan George
--
-- MIT license, http://opensource.org/licenses/MIT
-- ***************************************************************************

local moduleName = ...
local M = {}
_G[moduleName] = M

local address = "54.86.132.254" -- IP for data.sparkfun.com

if file.open('keys') then
    local line = file.readline()
    PuKey = string.sub(line,1,string.len(line)-1) --hack to remove CR/LF
    line = file.readline()
    PrKey = string.sub(line,1,string.len(line)-1)
    file.close()

function M.init(puKey, prKey)
  i2c.setup(id, sda, scl, i2c.SLOW)
  local calibration = read_reg(REG_CALIBRATION, 22)

  AC1 = twoCompl(string.byte(calibration, 1) * 256 + string.byte(calibration, 2))
  AC2 = twoCompl(string.byte(calibration, 3) * 256 + string.byte(calibration, 4))
  AC3 = twoCompl(string.byte(calibration, 5) * 256 + string.byte(calibration, 6))
  AC4 = string.byte(calibration, 7) * 256 + string.byte(calibration, 8)
  AC5 = string.byte(calibration, 9) * 256 + string.byte(calibration, 10)
  AC6 = string.byte(calibration, 11) * 256 + string.byte(calibration, 12)
  B1 = twoCompl(string.byte(calibration, 13) * 256 + string.byte(calibration, 14))
  B2 = twoCompl(string.byte(calibration, 15) * 256 + string.byte(calibration, 16))
  MB = twoCompl(string.byte(calibration, 17) * 256 + string.byte(calibration, 18))
  MC = twoCompl(string.byte(calibration, 19) * 256 + string.byte(calibration, 20))
  MD = twoCompl(string.byte(calibration, 21) * 256 + string.byte(calibration, 22))

  init = true
end

function sendData()

    tmr.alarm(1,1000,1,function()
        print("connecting")
        if (wifi.sta.status()==5) then
            print("connected")
            sk = net.createConnection(net.TCP, 0)
            sk:on("reconnection",function(conn) print("socket reconnected") end)
            sk:on("disconnection",function(conn) print("socket disconnected") end)
            sk:on("receive", function(conn, msg)
                print(msg)
                local success = nil
                _,_,success = string.find(msg, "success")
                if (success==nil) then
                    file.open('unsentData','a+')
                    file.writeline(currentDust.P1..","..currentDust.P2)
                    file.close()
                end
                wifi.sleeptype(1)
                wifi.sta.disconnect()
                end)
            sk:on("connection",function(conn) print("socket connected")
                print("sending...")
                -- change the name of 05umprticles and 1um_paricles here, or change the GET request for a different server if needed
                -- is not working right now...don't know why, it works as a string but not when joined...
                sendStr = "GET /input/"..PuKey.."?private_key="..PrKey.."&fahrenheit="..currentDust.P2.."&mmhg="..currentDust.P1
                conn:send(sendStr)
                print(sendStr)
                conn:send(" HTTP/1.1\r\n") 
                conn:send("Host: "..address)
                conn:send("Connection: close\r\n")
                conn:send("Accept: */*\r\n") 
                conn:send("User-Agent: Mozilla/4.0 (compatible; ESP8266;)\r\n") 
                conn:send("\r\n")
            end)
            sk:connect(80, address)
            tmr.stop(1)
        end
    end)
end