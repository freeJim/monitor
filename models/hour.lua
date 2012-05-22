
module(..., package.seeall)

local Model = require 'bamboo.model'
local View = require 'bamboo.view'
local Util = require 'app.util'

local AccessHour 
AccessHour = Model:extend {
    __tag = 'Bamboo.Model.AccessHour';
	__name = 'AccessHour';
	__desc = 'Abstract AccessHour node definition.';
--	__indexfd = 'title';
	__use_rule_index = false;
    __fields = {
		['year'] 			= {},
		['month'] 			= {},
		['day'] 			= {},
		['hour'] 			= {},
		['accesses'] 			= {foreign="Access",st="MANY"},
		['created_date'] 	= {},
		['last_modified_date'] 	= {},
		
	};

	
	init = function(self, t)
		if not t then 
            return self 
        end
		
        self.year   = t.year;
        self.month    = t.month;
        self.day  = t.day;
        self.hour   = t.hour;
        self.created_date       = os.time();
        self.last_modified_date = self.created_date;
		return self
	end;

    dump = function(self,count)
        count = count or 1;
        count = count-1;

        print("----------- Start AccessHour -----------");
        print("year",self.year);
        print("month",self.month);
        print("day",self.day);
        print("hour",self.hour);
        print("created_date:",self.created_date);
        print("last_modified_date:",self.last_modified_date);

        if count > 0 then
            Util.dumpForeign(self,"accesses",count);
        end

        print("----------- End AccessHour -----------");
    end
}



return AccessHour

