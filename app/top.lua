module(...,package.seeall)
Access = require 'models.access'
AccessHour = require 'models.accessHour'
IpCnt = require 'models.ipcnt'
Util = require 'app.util'
Upload = require 'bamboo.models.upload'

bamboo.registerModel(require 'models.access')
bamboo.registerModel(require 'models.accessHour')
bamboo.registerModel(require 'models.ipcnt')
bamboo.registerModule(require 'app.util')

local View = require 'bamboo.view'

--77:5:lgcms,12:182ll.150.2.59,5:50940#10:1335489802#3:GET,1:/,8:HTTP/1.1,3:200#1:0#]
function parse(record)
    if record == nil then
        return nil;
    end

    local s,e = string.find(record,":");
    if s == nil then
        return nil;
    end

    local t = {};
    local len=0; 
    
    local  start = e+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.host = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.rip = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.rport = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.time = string.sub(record,e+1,e+len);
    --t.time = tonumber(t.time) + 8*60*60; 
    --t.time = tostring(t.time);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.method = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.url = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.version = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.status = string.sub(record,e+1,e+len);

    start = e+1 + len+1;
    s,e = string.find(record,":",start);
    len = tonumber(string.sub(record,start,s-1));
    t.size = string.sub(record,e+1,e+len);

    return t;
end

function import_data(filename)
    local file = io.open("media/uploads/" .. filename,"r");
    if file == nil then
        return false,"no such file [".."media/uploads/"..filename.."]";
    end

    local cnt = 0;
    local accessH = nil
    for line in file:lines() do
        local access = Access(parse(line));
        access:save();

        accessH = split_hour(access,accessH);
        cnt = cnt +1;
        print(cnt);
    end
    io.close(file);

    return true,cnt
end

function top_ip_last(host,minutes)

end

--返回统计top100, 访问总次数，独立IP数
function retop_hour(hour)
    print("top_hour",hour.year,hour.month,hour.day,hour.hour);
    hour = generate_hour_idx(hour);
    local accessH = AccessHour:filter({ idx = hour.idx})[1];
    
    if accessH == nil then--没有访问数据 
        return {}, 0, 0, 0, 0;
    end

    --做IP——访问次数的HASH  
    local ip_count = {};
    local all = accessH:getForeign("accesses");
    for i,v in ipairs(all) do
        if ip_count[v.rip] == nil then 
            ip_count[v.rip] = 1;
        else
            ip_count[v.rip] = ip_count[v.rip] + 1;
        end
    end

    --top排序
    local top = {};
    for k,v in pairs(ip_count) do 
        table.insert(top,{rip=k,count=v});
    end
    table.sort(top,function(a,b) if a.count>b.count then return true end end);

    --更新TOP100
    accessH:deepClearForeign("top100");
    for i,v in ipairs(top) do
        if i<=100 then
            local ipcnt = IpCnt({ip=v.rip,cnt=v.count})
            ipcnt:save();
            accessH:addForeign("top100",ipcnt);
        end
    end

    --更新
    accessH.total = #all;
    accessH.ipnum = #top;
    accessH.topip = top[1].rip;
    accessH.topcnt= top[1].count;
    accessH:save();

    return accessH:getForeign("top100"),#all, #top, accessH.topip,accessH.topcnt;
end

--返回统计top100, 访问总次数，独立IP数
function top_hour(hour)
    print("top_hour");
    hour = generate_hour_idx(hour);
    local accessH = AccessHour:filter({idx = hour.idx })[1];
    
    if accessH == nil then 
        return retop_hour(hour);
    end
    
    local top100 = accessH:getForeign("top100");
    if top100:isEmpty() then
        return retop_hour(hour);
    end

    return top100, accessH.total, accessH.ipnum, accessH.topip, accessH.topcnt;
end

--返回统计top100, 访问总次数，独立IP数
function topday_hour(hour)
    print("topday_hour");
    hour = generate_hour_idx(hour);
    local accessH = AccessHour:filter({ idx=hour.idx})[1];
    
    if accessH==nil or accessH.ipnum==nil 
        or accessH.topip==nil or accessH.topcnt==nil then 
        return retop_hour(hour);
    end
    
    return {},accessH.total, accessH.ipnum, accessH.topip, accessH.topcnt;
end

function ip_detail(hour,rip)
    print("ipdetail",rip);
    hour = generate_hour_idx(hour);
    local accessH = AccessHour:filter({ idx=hour.idx})[1];
    
    if accessH == nil then 
        return {};
    end
    
    local all = accessH:getForeign("accesses");
    local records = {};
    if rip == nil or rip =="" then
        return all;
    end

    for i,v in ipairs(all) do
        if v.rip == rip then 
            table.insert(records,v);
        end
    end
    
    return records;
end

function write_to_file(filename, top, total, startTime, endTime)
    if filename == nil then
        filename = "/home/free/workspace/access.out";
    end

    local file = io.open(filename,"w");
    str = string.format("cnt:%d\ttotal:%d\tstartTime:%s\tendTime:%s\n"
                      ,#top,total,startTime,endtTime);
    file:write(str);
    for i,v in ipairs(ttt) do 
      local str = string.format("%s\t%d\n",v.rip,v.count);
      file:write(str);
    end
    io.close();
end

function generate_hour_idx(tdate) 
    if(type(tdate.year) == "number") then
        tdate.year = tostring(tdate.year);
    end

    if(type(tdate.month) == "number") then
        tdate.month = tostring(tdate.month);
    end

    if(type(tdate.day) == "number") then
        tdate.day = tostring(tdate.day);
    end

    if(type(tdate.hour) == "number") then
        tdate.hour = tostring(tdate.hour);
    end

    --std
    if string.len(tdate.month) == 1 then 
        tdate.month = "0"..tdate.month;
    end
    if string.len(tdate.day) == 1 then 
        tdate.day = "0" .. tdate.day;
    end
    if string.len(tdate.hour) == 1 then
        tdate.hour = "0" .. tdate.hour;
    end

    tdate.idx = tdate.year .. tdate.month .. tdate.day .. tdate.hour;

    return tdate;
end

function split_hour(access, accessH)
    local t = os.date("*t",access.time);
    t = generate_hour_idx(t);

    if accessH == nil or accessH.idx ~= t.idx then
        accessH = AccessHour:filter({idx=t.idx})[1];
    end

    if accessH == nil then
        accessH = AccessHour(t);

        accessH:save();
    end

    accessH:addForeign("accesses", access);
    return accessH;
end

--清除时段数据
function hour_clear(hour)
    print("hour_clear");
    hour = generate_hour_idx(hour);
    ptable(accessH);
    local accessH = AccessHour:filter({ idx=hour.idx})[1];
    
    if accessH == nil then 
        return false,"这个时段没有数据";
    end
    
    accessH:deepClearForeign("top100");
    accessH:deepClearForeign("accesses");
    accessH:del();

    return true;
end

