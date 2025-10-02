local cooldown = {};
cooldown.__index = cooldown;

function cooldown.new()
	local self = setmetatable({}, cooldown);
	self.cooldowns = {};
	return self;
end

function cooldown:addCooldown(player : Player, identifier : string, _time : number)
	if not self.cooldowns[player] then
		self.cooldowns[player] = {};
	end
	self.cooldowns[player][identifier] = tick() + _time;
end

function cooldown:isOnCooldown(player : Player, identifier : string)
	local onCooldown = false;
	if self.cooldowns[player] ~= nil and self.cooldowns[player][identifier] ~= nil then
		if self.cooldowns[player][identifier] > tick() then
			onCooldown = true;
		else
			self.cooldowns[player][identifier] = nil;
		end
	end
	return onCooldown;
end

function cooldown:deregister(player : Player)
	if self.cooldowns[player] ~= nil then
		self.cooldowns[player] = nil;
	end
end

return cooldown;
