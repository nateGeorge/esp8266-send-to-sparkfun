-- ***************************************************************************
-- data.sparkfun posting module for ESP8266 with nodeMCU
--
-- Written by Nate George
--
-- MIT license, http://opensource.org/licenses/MIT
-- ***************************************************************************

local moduleName = ...
local M = {}
_G[moduleName] = M

local address = "54.86.132.254" -- IP for data.sparkfun.com

local function loadKeys()
    if file.open('keys') then
        local line = file.readline()
        PuKey = string.sub(line,1,string.len(line)-1) -- hack to remove CR/LF
        line = file.readline()
        PrKey = string.sub(line,1,string.len(line)-1)
        file.close()
    end
end

function M.sendData(dataToSend, debug, pukey, prkey)
    -- sendData is a table of data to send, with keys as the data labels in sparkfun
    -- i.e. if you want to send some data to sparkfun which is labelled 'temperature',
    -- you would make sendData = {'temperature'=70}
    wifi.sta.connect()
    loadKeys()
    pukey = pukey or PuKey
    prkey = prkey or PrKey
    debug = debug or false
    tmr.alarm(1,1000,1,function()
        if debug then
            print("connecting")
        end
        if (wifi.sta.status()==5) then
            if debug then
                print("connected")
            end
            sk = net.createConnection(net.TCP, 0)
            sk:on("reconnection",function(conn) print("socket reconnected") end)
            sk:on("disconnection",function(conn) print("socket disconnected") end)
            sk:on("receive", function(conn, msg)
                if debug then
                    print(msg)
                end
                local success = nil
                _,_,success = string.find(msg, "(success)")
                print(success)
                if (success==nil) then
                    print('unsucessful send')
                else
                    print("great success, very nice, I like")
                end
                print(node.heap())
                end)
            sk:on("connection",function(conn)
                if debug then
                    print("socket connected")
                    print("sending...")
                end
                sendStr = "GET /input/"..PuKey.."?private_key="..PrKey
                for num, data in ipairs(dataToSend) do
                    sendStr = sendStr.."&"..data[1].."="..tostring(data[2]) -- hack to make it write to device
                end
                sendStr = sendStr.." HTTP/1.1\r\n".."Host: "..address.."\r\n"
                .."Connection: close\r\n"
                .."Accept: */*\r\n"
                .."User-Agent: Mozilla/4.0 (compatible; ESP8266;)\r\n"
                .."\r\n"
                conn:send(sendStr)
                if debug then
                    conn:on("sent",function() print("sent!") end)
                end
                print(sendStr)
                
            end)
            sk:connect(80, address)
            tmr.stop(1)
        end
    end)
end

return M
