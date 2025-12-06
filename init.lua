 --==[[ XM Group Chat ]]==--
  --==[[ monk © 2025 ]]==--
local modpath = core.get_modpath(core.get_current_modname())

local invite_ttl = 60  -- invite expiry in seconds
local xm_invites = {}

  -- rebuild the groups table from members data
local xm_groups = {}
local xm_members, save_xm_data = dofile(modpath .. "/data.lua")(xm_groups)

-- system message templates
local xmsg = dofile(modpath .. "/xmsg.lua")

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
    return false, xmsg.player_no_group_you

  elseif receiver_name and not receiver_name:match("^[a-zA-Z0-9_-]+$") then
    return false, xmsg.invite_usage -- "#! Usage: /xm_invite <player>"

  elseif not core.get_player_by_name(receiver_name) then
    return false, xmsg.player_offline_they:format(receiver_name)

  elseif has_invite(sender_name) then  -- rate-limit the inviter
    return false, xmsg.invite_rate_limit_you

  elseif has_invite(receiver_name) then
    return false, xmsg.invite_rate_limit_they:format(receiver_name)

  elseif get_group_id(receiver_name) then
    return false, xmsg.player_group_conflict_they:format(receiver_name) -- "#! Player is already in a group."
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

  -- local invite_announce = "#! %s invited %s to join the XM group! %s"
  broadcast_message(group_id, xmsg.invite_notify_group:format(sender_name, receiver_name))

  core.chat_send_player(receiver_name, xmsg.invite_notify_they:format(sender_name))

  return true
end


-- join a group via invite
local function join_invited(player_name)
  if get_group_id(player_name) then
    return false, xmsg.player_group_conflict_you
  end

  local pending = has_invite(player_name)

  if not pending or type(pending) ~= "table" then
    return false, xmsg.join_no_invite_you
  end

  local group_id = pending.group_id

  if not group_id or not get_group_by_id(group_id) then
    return false, xmsg.join_group_missing
  end

  xm_groups[group_id][player_name] = true
  xm_members[player_name] = group_id

  save_xm_data(xm_members)

  broadcast_message(group_id,
      xmsg.join_notify_group:format(
        core.colorize("#00EE22", player_name)))

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
    return false, xmsg.player_no_group_you
  end

  broadcast_message(group_id,
      xmsg.leave_notify_group:format(
          core.colorize("#EE0022", player_name)))

  xm_groups[group_id][player_name] = nil
  xm_members[player_name] = nil

  -- remove group if empty
  local group = xm_groups[group_id]

  if not next(group) then
    xm_groups[group_id] = nil
  end

  save_xm_data(xm_members)

  return true
end


-- Create new group
core.register_chatcommand("xm-new", {
  description = xmsg.cmd_new,
  privs = {shout = true},
  func = function(name)
    if get_group_id(name) then
      return false, xmsg.player_group_conflict_you
    end

    new_group(name)

    return true, xmsg.group_new
  end
})

-- Invite player
core.register_chatcommand("xm-invite", {
  params = "<player>",
  description = xmsg.cmd_invite,
  func = function(inviter, param)
    local ok, msg = send_invite(param, inviter)
    return ok, msg
  end
})

-- Join group
core.register_chatcommand("xm-join", {
  description = xmsg.cmd_join,
	privs = {shout = true},
  func = function(name)
    local ok, msg = join_invited(name)
    return ok, msg
  end
})

-- Leave group
core.register_chatcommand("xm-quit", {
  description = xmsg.cmd_quit,
  func = function(name)
    local ok, msg = leave_group(name)
    return ok, msg
  end
})


-- Send message to XM group
core.register_chatcommand("xm", {
  params = "<message>",
  description = xmsg.cmd_xm,
  privs = {shout = true},
  func = function(sender, message)
    local group_id = get_group_id(sender)

    if not group_id then
      return false, xmsg.player_no_group_you

    elseif message == "" then
      return false, xmsg.group_xm_usage
    end

    broadcast_message(group_id,
        xmsg.group_xm_send:format(
            sender, core.colorize("#00EEAA", message)))

    return true
  end
})


core.register_chatcommand("xm-list", {
  params = "[player]",
  description = xmsg.cmd_list,
  func = function(name, param)
    local target = param:match("[a-zA-Z0-9_-]+")
        and param or name

    if not core.player_exists(target) then
      return false, xmsg.player_not_found_they:format(target)

    elseif not core.get_player_by_name(target) then
      return false, xmsg.player_offline_they
    end

    local group_id = get_group_id(target)
    local group = group_id and xm_groups[group_id]

    if not group then
      if param ~= "" then
          return false, xmsg.player_no_group_they
      else
          return false, xmsg.player_no_group_you
      end
    end

    local members = {}
    local total_online = 0
    for member, online in pairs(group) do
      total_online = online and total_online + 1 or total_online
      local color = online and "green" or "red"
      local colored_name = core.colorize(color, member)
      table.insert(members, colored_name)
    end

    table.sort(members)

    return true, xmsg.group_members:format(target,
      total_online, #members, table.concat(members, ", "))
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


core.register_chatcommand("xm-dump", {
  description = xmsg.cmd_dump,
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
