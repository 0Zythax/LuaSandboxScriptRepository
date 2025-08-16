local tweenService = game:GetService('TweenService');
local animation = {};
animation.__index = animation;

function animation.new(source)
	local self = setmetatable({}, animation);

	self.sequence = typeof(source) == 'table' and source or require(source);

	self.playing = false;
	self.looped = false;
	self.animationSpeed = 1;
	self.tweeningEnabled = true;

	self.keyframe = 1;
	self.lastKeyframe = 1;
	self.animator = nil;

	return self;
end

function animation:resume()
	if not self.animator then warn("No animator is handling this Animation!") end;
	self.playing = true;
end

function animation:pause()
	if not self.animator then warn("No animator is handling this Animation!") end;
	self.playing = false;
end

function animation:stop()
	if not self.animator then warn("No animator is handling this Animation!") end;
	self.animator.stopPlayingAnimations(self.animator);
end

function animation:changeSpeed(newSpeed)
	if not self.animator then warn("No animator is handling this Animation!") end;
	if newSpeed then
		self.animationSpeed = math.clamp(newSpeed, 1, 5)
	end
end

function animation:loop(toggle)
	if not self.animator then warn("No animator is handling this Animation!") end;
	self.looped = toggle;
end

local animator = {};
animator.__index = animator;

function animator.new(character : Model)
	local self = setmetatable({}, animator);

	self.character = character;
	self.humanoid = self.character:WaitForChild('Humanoid', 5);

	self.defaultC0 = {};
	self.joints = {};
	self.tweens = {};

	self.currentAnimation = nil;

	self:initalise();
	return self;
end

function animator:initalise()
	for _, joint in next, self.character:GetDescendants() do
		if joint:IsA("JointInstance") and joint.Part1 then
			local jointName = joint.Part1.Name;
			self.joints[jointName] = joint;
			self.defaultC0[jointName] = joint.C0;
		end
	end
end

function animator:resetJoints()
	for jointName, C0 in next, self.defaultC0 do
		self.joints[jointName].C0 = C0;
	end
end

function animator:toggleAnimateScript(toggle : boolean)
	local animate = self.character:FindFirstChild("Animate");
	if animate then
		animate.Enabled = toggle;
	end
end

function animator:playAnimation(animation)
	if self.currentAnimation ~= nil then
		self:stopPlayingAnimations()
	end

	self:toggleAnimateScript(false);
	self.currentAnimation = animation;
	self.currentAnimation.animator = self;
	self.currentAnimation.playing = true;

	self.currentAnimation.thread = task.spawn(function()
		while self.currentAnimation.playing do
			local actualKeyframe = self.currentAnimation.sequence[self.currentAnimation.keyframe];
			local actualLastKeyframe = self.currentAnimation.sequence[self.currentAnimation.lastKeyframe];
			local keyframeTime = (actualKeyframe.tm - actualLastKeyframe.tm) * (1 / self.currentAnimation.animationSpeed);

			for jointName, jointMovementData in next, actualKeyframe do
				local joint = self.joints[jointName];
				local defaultC0 = self.defaultC0[jointName];

				if joint and defaultC0 then
					if not self.currentAnimation.tweeningEnabled then
						joint.C0 = defaultC0 * jointMovementData.cf;
					else
						jointMovementData.es = jointMovementData.es or "Linear";
						jointMovementData.ed = jointMovementData.ed or "In";
						local tween = tweenService:Create(joint, TweenInfo.new(keyframeTime, Enum.EasingStyle:FromName(jointMovementData.es), Enum.EasingDirection:FromName(jointMovementData.ed)), {
							C0 = defaultC0 * jointMovementData.cf;
						});
						table.insert(self.tweens, tween);
						tween:Play();
					end
				end
			end

			task.wait(keyframeTime);

			self.currentAnimation.lastKeyframe = self.currentAnimation.keyframe 
			self.currentAnimation.keyframe = math.clamp(self.currentAnimation.keyframe + 1, 1, #self.currentAnimation.sequence);

			if self.currentAnimation.keyframe == #self.currentAnimation.sequence then
				if not self.currentAnimation.looped then break end;
				self.currentAnimation.keyframe = 1;
				continue;
			end

			if not self.currentAnimation.playing then
				break;
			end
		end

		self:stopPlayingAnimations();
	end)
end

function animator:stopPlayingAnimations()
	if self.currentAnimation then
		self.currentAnimation.keyframe = 1;
		self.currentAnimation.animationSpeed = 1;
		self.currentAnimation.lastKeyframe = 1;
		self.currentAnimation.playing = false;

		if self.currentAnimation.thread then
			-- yes, this errors from the thread loop but that doesn't really matter tbh cuz its terminated anyways
			pcall(function()
				task.cancel(self.currentAnimation.thread)
			end)
			self.currentAnimation.thread = nil;
		end

		self.currentAnimation.animator = nil;
		self.currentAnimation = nil;
	end

	for _, tween in next, self.tweens do
		pcall(function()
			tween:Cancel();
		end)
	end; self.tweens = {};

	self:resetJoints();
	self:toggleAnimateScript(true);
end
