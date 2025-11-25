 --==[[ XM Group Chat ]]==--
  --==[[ monk © 2025 ]]==--
local invite_ttl = 60  -- invite expiry in seconds
local xm_invites = {}
local xm_groups = {}
local xm_members, save_xm_data = dofile(
    core.get_modpath(core.get_current_modname()) .. "/data.lua")(xm_groups)


-- generate unique group id from the first 12 chars of sha1
local function create_unique_id(player_name)
  while true do
    local uid_string = string.format("%s_%d_%d",
        player_name, os.time(), math.random(0, 1e9)
      )
    local group_id = core.sha1(uid_string):sub(1,12)

    if not xm_groups[group_id] then
      return group_id
    end
  end
end

-- create a new XM group for a player
local function new_group(player_name)
  local group_id = create_unique_id(player_name)
  xm_groups[group_id] = {[player_name] = true}
  xm_members[player_name] = group_id

  save_xm_data(xm_members)
  return group_id
end

local function get_group_id(player_name)
  return xm_members[player_name]
end

local function get_group_by_id(group_id)
  return group_id and xm_groups[group_id]
end

-- check if a player has a pending invite
local function has_invite(player_name)
  return xm_invites[player_name]
end

-- send event messages to group
local function broadcast_message(group_id, message)
  local group = get_group_by_id(group_id)
  for member, online in pairs(group) do
    if online then
      core.chat_send_player(member, message)
    end
  end
end


-- invite a player to a group
local function send_invite(receiver_name, sender_name)
  local group_id = get_group_id(sender_name)

  if not group_id then
    return false, "#! You are not in a group."

  elseif receiver_name and not receiver_name:match("^[a-zA-Z0-9_-]+$") then
    return false, "#! Usage: /xm_invite <player>"

  elseif not core.get_player_by_name(receiver_name) then
    return false, "#! Unable to invite an offline player!"

  elseif has_invite(sender_name) then  -- rate-limit the inviter
    return false, "#! You are sending invites too often."

  elseif has_invite(receiver_name) then
    return false, "#! Player already has a pending invite."

  elseif get_group_id(receiver_name) then
    return false, "#! Player is already in a group."
  end

  xm_invites[sender_name] = true

  -- set the invite with a timeout
  xm_invites[receiver_name] = {
    group_id = group_id,
    timeout = core.after(invite_ttl, function()
      xm_invites[sender_name] = nil
      xm_invites[receiver_name] = nil
    end)
  }

  local invite_announce = "#! %s invited %s to join the XM group! %s"

  broadcast_message(group_id, invite_announce:format(sender_name, receiver_name, ""))

  core.chat_send_player(receiver_name, invite_announce:format(sender_name, "you", "To accept, use /xm_join"))

  return true
end


-- join a group via invite
local function join_invited(player_name)
  if get_group_id(player_name) then
    return false, "#! You are already in an XM group!"
  end

  local pending = has_invite(player_name)

  if not pending or type(pending) ~= "table" then
    return false, "#! You have no valid invite."
  end

  local group_id = pending.group_id

  if not group_id or not get_group_by_id(group_id) then
    return false, "#! Invalid invite, group doesn't exist."
  end

  xm_groups[group_id][player_name] = true
  xm_members[player_name] = group_id

  local announce_join = string.format(
    "#! %s joined the xm group!", core.colorize("#00EE22", player_name)
  )

  broadcast_message(group_id, announce_join)

  save_xm_data(xm_members)
  return true
end


-- rejoin after leaving game
local function update_online_status(player_name, status)
  local group_id = get_group_id(player_name)
  local group_exists = get_group_by_id(group_id)

  if group_exists then
    xm_groups[group_id][player_name] = status

    if status == false then -- on_playerleave
      for member, _ in pairs(group_exists) do
        if member ~= player_name then
            -- exit early if at least one other member exists
          return
        end
      end
      -- otherwise we cull groups containing only 1 member
      xm_groups[group_id] = nil
      xm_members[player_name] = nil
      save_xm_data(xm_members)
    end
  elseif group_id then  -- stale or missing group
    xm_members[player_name] = nil
    save_xm_data(xm_members)
  end
end


-- leave current group
local function leave_group(player_name)
  local group_id = get_group_id(player_name)
  if not group_id then
    return false, "#! You are not in a group."
  end

  xm_groups[group_id][player_name] = nil
  xm_members[player_name] = nil

  -- remove group if empty
  local group = xm_groups[group_id]

  if not next(group) then
    xm_groups[group_id] = nil

  else
    local announce_leave = string.format(
      "#! %s left the xm group.", core.colorize("#EE0022", player_name)
    )
    broadcast_message(group_id, announce_leave)
  end

  save_xm_data(xm_members)
  return true
end



-- Create new group
core.register_chatcommand("xm_new", {
  description = "Create a new XM group",
  privs = {shout = true},
  func = function(name)
    if get_group_id(name) then
      return false, "#! You are already in an XM group."
    end
    new_group(name)
    return true, "#! XM group created successfully."
  end
})

-- Invite player
core.register_chatcommand("xm_invite", {
  params = "<player>",
  description = "Invite a player to your XM group",
  func = function(inviter, param)
    local ok, msg = send_invite(param, inviter)
    return ok, msg or ("#! Invite sent to " .. param)
  end
})

-- Join group
core.register_chatcommand("xm_join", {
  description = "Join your pending XM invite",
	privs = {shout = true},
  func = function(name)
    local ok, msg = join_invited(name)
    return ok, msg or "#! You joined the XM group."
  end
})

-- Leave group
core.register_chatcommand("xm_leave", {
  description = "Leave your XM group",
  func = function(name)
    local ok, msg = leave_group(name)
    return ok, msg or "#! You left the XM group."
  end
})


-- Send message to XM group
core.register_chatcommand("xm", {
  params = "<message>",
  description = "Send a message to your XM group",
  privs = {shout = true},
  func = function(sender, message)
    local group_id = get_group_id(sender)
    if not group_id then
      return false, "#! You are not in an XM group."
    elseif message == "" then
      return false, "#! Usage: /xm <message>"
    end

    local formatted_message = string.format(
      "#/xm %s %s", sender, core.colorize("#00EEAA", message)
    )
    broadcast_message(group_id, formatted_message)
    return true
  end
})


core.register_chatcommand("xm_list", {
  params = "[player]",
  description = "List members of your XM group, or another player's group",
  func = function(name, param)
    local target = param:match("[a-zA-Z0-9_-]+") and param or name

    if not core.player_exists(target) then
      return false, "#! Player does not exist."
    elseif not core.get_player_by_name(target) then
      return false, "#! Player is offline."
    end

    local group_id = get_group_id(target)
    local group = group_id and xm_groups[group_id]

    if not group then
      if param ~= "" then
          return false, "#! " .. target .. " is not in an XM group."
      else
          return false, "#! You are not in an XM group."
      end
    end

    local members = {}
    for member, online in pairs(group) do
      local color = online and "green" or "red"
      local colored_name = core.colorize(color, member)
      table.insert(members, colored_name)
    end

    table.sort(members)

    return true, "#! XM Group members (" .. #members .. "): " .. table.concat(members, ", ")
  end
})


core.register_on_joinplayer(function(player)
  if player then
    update_online_status(player:get_player_name(), true)
  end
end)

core.register_on_leaveplayer(function(player)
  if player then
    update_online_status(player:get_player_name(), false)
  end
end)

core.register_on_shutdown(function()
  local online_players = core.get_connected_players()
  for _, player in ipairs(online_players) do
    update_online_status(player:get_player_name(), false)
  end
  save_xm_data(xm_members)
end)


core.register_chatcommand("xm_dump", {
  description = "Dump xm data to log",
  privs = {server = true},
  func = function(name)
    local xm = {
      xm_groups, xm_members, xm_invites
    }
    core.log("action", dump(xm))
  end
})
------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2025 monk  https://github.com/monk-afk/xm_groupchat                --
--                                                                                --
-- Permission is hereby granted, free of charge, to any person obtaining a copy   --
-- of this software and associated documentation files (the "Software"), to deal  --
-- in the Software without restriction, including without limitation the rights   --
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      --
-- copies of the Software, and to permit persons to whom the Software is          --
-- furnished to do so, subject to the following conditions:                       --
--                                                                                --
-- The above copyright notice and this permission notice shall be included in all --
-- copies or substantial portions of the Software.                                --
--                                                                                --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     --
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       --
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    --
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         --
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  --
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  --
-- SOFTWARE.                                                                      --
------------------------------------------------------------------------------------
