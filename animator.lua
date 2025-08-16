--[[
animator.lua
@0zythax
cframe animation wowwww
]]

local players = game:GetService('Players');
local tweenService = game:GetService('TweenService');

local owner = players:WaitForChild('itpaw');
local character = owner.Character or owner.CharacterAdded:Wait();

-- animation object
local animation = {};
animation.__index = animation;

function animation.new(src)
	local self = setmetatable({}, animation);

	self.sequence = typeof(src) == 'table' and src or require(src);
	self.useTween = true;

	self.animator = nil;
	self.tweens = {};
	self.threads = {};
	
	self.looping = false;
	self.playing = false;
	self.animationSpeed = 1;
	self.keyframe = 0;
	self.lastKeyframe = 0;

	return self;
end

-- private do not call
function animation:_cancel()
	for _, thread in next, self.threads do
		pcall(function()
			task.cancel(thread);
		end)
	end

	for _, tween in next, self.tweens do
		tween:Cancel();
	end
	
	if self.animator ~= nil then
		self.animator.ResetJoints(self.animator);
		self.animator.disableAnimateScript(self.animator, false);
	end
end

-- changes speed
function animation:ChangeSpeed(newSpeed : number)
	self.animationSpeed = newSpeed;
end

-- toggles .looped
function animation:ToggleLoop(toggle : boolean)
	self.looping = toggle;
end

-- stops
function animation:Stop()
	self:_cancel();
	self = nil;
end

-- plays
function animation:Play()
	if self.playing then return warn('already playing') end;
	self.playing = true;
	self.animator:PlayAnimation(self, false);
end

-- pauses
function animation:Pause()
	if not self.playing then return warn('cannot pause a animation that isnt even playing') end
	self:_cancel();
	self.playing = false;
end

-- animator object
local animator = {};
animator.__index = animator;

function animator.new(character)
	local self = setmetatable({}, animator);
	self.character = character;

	self.joints = {};
	self.defaultc0 = {};
	self.currentAnimation = nil;

	self:init();
	return self;
end

-- gets stuff for the animator
function animator:init()
	for _, joint in next, self.character:GetDescendants() do
		if joint:IsA('JointInstance') then
			local name = joint.Part1 ~= nil and joint.Part1.Name or "";
			self.joints[name] = joint;
			self.defaultc0[name] = joint.C0;
		end
	end
end

-- toggles the 'Animate' script
function animator:disableAnimateScript(toggle : boolean)
	local animate = character:FindFirstChild('Animate');
	if animate then
		animate.Disabled = toggle;
	end
end

-- play a animation
function animator:PlayAnimation(animationObject, ...)
	-- TODO make this not ass
	self:disableAnimateScript(true)
	self.currentAnimation = animationObject;
	self.currentAnimation.playing = true;
	
	if ... ~= false then
		self.currentAnimation.animator = self;
		self.currentAnimation.keyframe = 1;
		self.currentAnimation.lastKeyframe = 1;
	end
	
	local sequence = self.currentAnimation.sequence;
	local function doAnimation()
		for keyframe = self.currentAnimation.keyframe, #sequence do
			table.insert(self.currentAnimation.threads, task.delay(sequence[keyframe].tm, function()
				local actualKeyframe = sequence[self.currentAnimation.keyframe];
				local actualLastKeyframe = sequence[self.currentAnimation.lastKeyframe]

				for jointName, jointMovementData in next, actualKeyframe do
					local keyframeDuration = (actualKeyframe.tm - actualLastKeyframe.tm) * (1 / animationObject.animationSpeed);
					local joint = self.joints[jointName];

					if joint ~= nil then
						if not self.currentAnimation.useTween then
							joint.C0 = (self.defaultc0[jointName] * jointMovementData.cf)
						else
							local tween = tweenService:Create(joint, 
								TweenInfo.new(keyframeDuration, Enum.EasingStyle:FromName(jointMovementData.es), Enum.EasingDirection:FromName(jointMovementData.ed)), 
								{['C0'] = self.defaultc0[jointName] * jointMovementData.cf}
							);
							table.insert(self.currentAnimation.tweens, tween);
							tween:Play();
						end
					end
				end
				
				self.currentAnimation.lastKeyframe = self.currentAnimation.keyframe
				self.currentAnimation.keyframe += 1;
				
				if self.currentAnimation.keyframe >= #sequence then
					if self.currentAnimation.looping then
						self.currentAnimation.keyframe = 1;
						self.currentAnimation.lastKeyframe = 1;
						doAnimation();
						return;
					end
					
					task.wait(0.02);
					self:ResetJoints();
					self:disableAnimateScript(false);
				end
			end));
		end
	end
	
	doAnimation();
end

-- reset joints
function animator:ResetJoints()
	for jointName, c0 in next, self.defaultc0 do
		self.joints[jointName].C0 = c0;
	end
end

-- stop currently playing animations (if you lose the animation object somehow Lol)
function animator:StopPlayingAnimations()
	if self.currentAnimation then
		self.currentAnimation:Stop();
		self:ResetJoints();
		self:disableAnimateScript(false)
		self.currentAnimation = nil;
	end
end

-- obligatory :Destroy function
function animator:Destroy()
	self:StopPlayingAnimations();
	self = nil;
end
