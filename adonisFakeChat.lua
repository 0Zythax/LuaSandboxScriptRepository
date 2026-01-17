--[[
adonisFakeChat.lua
@0zythax
you can totally make this work with just a loadstring, but this was mainly made for Adonis
i never ended up finishing the bubble chat mode switcher, sorry
]]

local chatService = game:GetService("Chat");
local players = game:GetService("Players");
local replicatedStorage = game:GetService("ReplicatedStorage");
local httpService = game:GetService("HttpService");

local remoteNameIdentifier = `fakechat{string.gsub(httpService:GenerateGUID(false),"-","")}`
local adonisKey = "enterGaccesskeyhere";
local targetPlayer = players:FindFirstChild("itpaw")
local targetCharacter;

local fakeChatConnections = {};
local playerChattedConnections = {};

if targetPlayer == nil then warn(`{targetPlayer} does not exist`) return end;
targetCharacter = targetPlayer.Character or targetPlayer.CharacterAdded:Wait();

local _warn, _print = warn, print;
warn, print = function(...) _warn("[fakechat] ", ...) end, function(...) _print("[fakechat] ", ...) end;

if _G.Adonis == nil then warn("could not find _G.Adonis, please ensure that the game has fully loaded, Adonis is present and the _G api for Adonis is activated before attempting to use fakechat") return end;
local adonisRemote = _G.Adonis.Access(adonisKey, "Remote")
local adonisLogs = _G.Adonis.Access(adonisKey, "Logs")
local adonisAdmin = _G.Adonis.Access(adonisKey, "Admin")

local remote = Instance.new("RemoteEvent");
remote.Name = remoteNameIdentifier;
remote.Parent = replicatedStorage;

-- chat function
local function chat(message : string)
	chatService:Chat(targetCharacter, message, Enum.ChatColor.White);
	adonisLogs.AddLog("Chats", {
		Text = `{targetPlayer.Name}: [fakechat-user] {message}`;
		Desc = tostring(message);
		Player = targetPlayer;
	})
end

-- directory of remote event functions (...)
local remoteFunctions = {
	["chat"] = chat;
	["destroy"] = function()
		for _, connection in next, fakeChatConnections do
			connection:Disconnect();
		end; fakeChatConnections = nil;
		
		for _, connection in next, playerChattedConnections do
			connection:Disconnect();
		end; playerChattedConnections = nil;
		
		remote:Destroy();
		print(`fakechat instance for {targetPlayer} has been destroyed`);
	end,
}

-- upon the remote being called upon
local function onServerEvent(caller : Player, request : string, ...)
	if caller ~= targetPlayer then return end;
	if remoteFunctions[request] == nil then return warn(`{request} is not valid`) end;
	remoteFunctions[request](...);
end

-- player added
local function playerAdded(player : Player)
	if player == targetPlayer then return end; -- do not add to self, this emulates chat bubbles for other people
	playerChattedConnections[player] = player.Chatted:Connect(function(message : string)
		remote:FireClient(targetPlayer, player, message);
	end)
end

-- player removed
local function playerRemoving(player : Player)
	if player == targetPlayer then
		remoteFunctions["destroy"]();
		return;
	end
	
	if playerChattedConnections[player] ~= nil then
		playerChattedConnections[player]:Disconnect();
		playerChattedConnections[player] = nil;
	end
end

-- target player character added
local function targetPlayerCharacterAdded(character)
	targetCharacter = character;
end

-- connections
for _, player in next, players:GetPlayers() do playerAdded(player); end;
table.insert(fakeChatConnections, players.PlayerAdded:Connect(playerAdded));
table.insert(fakeChatConnections, remote.OnServerEvent:Connect(onServerEvent));
table.insert(fakeChatConnections, targetPlayer.CharacterAdded:Connect(targetPlayerCharacterAdded));
table.insert(fakeChatConnections, players.PlayerRemoving:Connect(playerRemoving));

-- local code
adonisRemote.LoadCode(targetPlayer, string.format([[
-- services
local uis = game:GetService("UserInputService")
local chat = game:GetService("Chat")
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- bindables
local openKeybind = Enum.KeyCode.Slash
local dieKeybind = Enum.KeyCode.F5
local changeChatTypeKeybind = Enum.KeyCode.F6

-- state variables
local open = false
local busy = false
local fakeChatConnections = {}

-- player stuff
local localPlayer = players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local remote = nil

-- debug stuff
local _warn, _print = warn, print;
warn, print = function(...) _warn("[fakechat] ", ...) end, function(...) _print("[fakechat] ", ...) end;

-- wait for remote
local attempts = 5 
local oldAttempts = attempts + 1
while task.wait(1) do
	print("waiting for fakeChat remote")
	attempts = attempts - 1
	remote = replicatedStorage:FindFirstChild("%s")
	if remote ~= nil or attempts <= 0 then
		break
	end
end

-- failed
if attempts <= 0 then
	warn("remote %s not found")
	return
end

-- make ui
local chatGUI = Instance.new("ScreenGui")
chatGUI.Name = "fakeChatGUI"
chatGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
chatGUI.ResetOnSpawn = false
chatGUI.Parent = playerGui

local container = Instance.new("Frame")
container.Name = "container"
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
container.BackgroundTransparency = 1
container.BorderColor3 = Color3.fromRGB(0, 0, 0)
container.BorderSizePixel = 0
container.Position = UDim2.fromScale(0.5, 0.5)
container.Size = UDim2.fromScale(1, 1)

local box = Instance.new("Frame")
box.Name = "chatBox"
box.AnchorPoint = Vector2.new(0.5, 0.5)
box.BackgroundColor3 = Color3.fromRGB(48, 48, 48)
box.BorderColor3 = Color3.fromRGB(0, 0, 0)
box.BorderSizePixel = 0
box.Position = UDim2.fromScale(0.888, 1.2)
box.Size = UDim2.fromScale(0.194, 0.0652)

local content = Instance.new("TextBox")
content.Name = "content"
content.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
content.PlaceholderText = "Type your message, then press [ENTER] to send."
content.Text = ""
content.TextColor3 = Color3.fromRGB(255, 255, 255)
content.TextScaled = true
content.TextSize = 10
content.TextWrapped = true
content.TextXAlignment = Enum.TextXAlignment.Left
content.TextYAlignment = Enum.TextYAlignment.Top
content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
content.BackgroundTransparency = 1
content.BorderColor3 = Color3.fromRGB(0, 0, 0)
content.BorderSizePixel = 0
content.Position = UDim2.fromScale(0.0342, 0.107)
content.Size = UDim2.fromScale(0.951, 0.786)
content.ClearTextOnFocus = false
content.TextEditable = false
content.Parent = box

local label = Instance.new("TextLabel")
label.Name = "modeLabel"
label.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
label.Text = "Speech Bubble mode: ChatService"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.TextSize = 14
label.TextStrokeTransparency = 0
label.TextWrapped = true
label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
label.BackgroundTransparency = 1
label.BorderColor3 = Color3.fromRGB(0, 0, 0)
label.BorderSizePixel = 0
label.Position = UDim2.fromScale(-0.00323, -0.714)
label.Size = UDim2.fromScale(1, 0.714)
label.Parent = box

box.Parent = container
container.Parent = chatGUI
-- end of make ui

-- tweens
local globalTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local openTween = tweenService:Create(box, globalTweenInfo, {Position = UDim2.fromScale(0.888, 0.943)})
local closeTween = tweenService:Create(box, globalTweenInfo, {Position = UDim2.fromScale(0.888, 1.25)})

local inputFunctions = {

	-- open fakeChat ui
	[openKeybind] = function()
		if open == true then
			-- close
			content.TextEditable = false
			closeTween:Play()
			open = false
			closeTween.Completed:Once(function()
				busy = false
			end)
		else
			-- open
			openTween:Play()
			open = true
			content.TextEditable = true
			task.wait(0.1);
			content:CaptureFocus()
			openTween.Completed:Once(function()
				busy = false
			end)
		end
	end,

	-- destroy fakeChat
	[dieKeybind] = function()
		for _, connection in next, fakeChatConnections do
			connection:Disconnect()
		end fakeChatConnections = nil
		chatGUI:Destroy()
		remote:FireServer("destroy")
		busy = false
	end,

	-- change chat type
	[changeChatTypeKeybind] = function()
		busy = false
		return
	end,
}

-- keybind listener
local function inputBegan(input, gpe)
	if gpe == true or busy == true then return end
	if inputFunctions[input.KeyCode] == nil then return end
	inputFunctions[input.KeyCode]()
	busy = true
end

-- onClientEvent all it rlly sends is A string
local function onClientEvent(player, message)
	local character = player.Character
	if character == nil then return end -- character not rendered? do not even bother with this Guy
	chat:Chat(character, message, Enum.ChatColor.White)
end

-- focus lost on chat box
local function focusLost(enterPressed)
	busy = true
	open = false

	closeTween:Play()
	closeTween.Completed:Once(function()
		busy = false
	end)

	if enterPressed then
		if string.len(content.Text) <= 0 then return end -- do not send a message if the box is empty
		remote:FireServer("chat", content.Text)
	end content.Text = ""
end

-- connections
table.insert(fakeChatConnections, remote.OnClientEvent:Connect(onClientEvent))
table.insert(fakeChatConnections, uis.InputBegan:Connect(inputBegan))
table.insert(fakeChatConnections, content.FocusLost:Connect(focusLost))

print("client is ready")
]], remoteNameIdentifier, remoteNameIdentifier));

print("server is ready");
