-- ok
local utilities = {};

function utilities.deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = utilities.deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

return setmetatable(utilities, {
	__index = function(self, i)
		if self[i] then return self[i] end;
		if script[i] then return require(script[i]) end;
		return nil;
	end,
	__metatable = "6 7"
})
