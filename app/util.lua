module (...,package.seeall)


function getIdTable(objList)
    local tbl = {};

    if objList then
        for i,v in ipairs(objList) do
            tbl[v.id] = v;
        end
    end

    return tbl;
end


function dumpForeign( obj, foreignKey, count)
    local foreign = obj:getForeign(foreignKey);
    
    if foreign == nil then
        print(string.format("FOREIGN [%s] is nil",foreignKey));
        return ;
    end

    print(string.format("FOREIGN [%s, %s]:",foreignKey,type(foreign)));
    if type(foreign) == "string" then
        print(foreign);
    else
        if foreign.dump then
            foreign:dump(count);
        else 
            print("    foreign object.dump == nil");
        end
    end
end

function namesToCategories( namesStr)
    local Category = require('models.category')
    local names = string.split( namesStr, ',');
    local categories = List();
    for i,v in ipairs(names) do
        local category = nil;
        if i == 1 then
            category = Category:filter({name=v,extra=uneq("category")})[1];
        else
            category = Category:filter({name=v,extra=names[i-1]})[1];
        end

        if category then 
            categories:append(category);
        end
    end

    return categories;
end

function articlesListTitle(articles, titleLen, rowNumber)
    if rowNumber == nil then
        rowNumber = #articles;
    end

    print(rowNumber);
    for i,v in ipairs(articles) do 
        if i > rowNumber then
            break;
        end

        if string.utf8len(v.title) > titleLen then
            v.title = string.utf8slice(v.title,1,titleLen);
            v.title = v.title + "...";
        end

        v.last_modified_date = os.date("%m-%d",v.last_modified_date);
    end
end
function videosListName(videos, nameLen, rowNumber)
    if rowNumber == nil then
        rowNumber = #videos;
    end

    for i,v in ipairs(videos) do 
        if i > rowNumber then
            break;
        end

        if string.utf8len(v.name) > nameLen then
            v.name = string.utf8slice(v.name,1,nameLen);
            v.name = v.name + "...";
        end
        v.last_modified_date = os.date("%m-%d",v.last_modified_date);
    end
end

-- timeString Format %Y-%m-%d %H:%M:%S" 
function timeStr2Struct(timeStr)
    local timeStr = timeStr:gsub("%-"," ");
    timeStr = timeStr:gsub("%:"," ");
    local t = string.split(timeStr," ");

    local sTime = {};
    sTime.year = tonumber(t[1]);
    sTime.month = tonumber(t[2]);
    sTime.day = tonumber(t[3]);
    sTime.hour = tonumber(t[4]);
    sTime.min = tonumber(t[5]);
    sTime.second = tonumber(t[6]);

    return sTime;
end


