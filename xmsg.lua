-- system messages and command description templates
return {
  player_no_group_you        = "#! You are not in an XM Group!",
  player_not_found_they      = "#! <%s> does not exist!",
  player_group_conflict_they = "#! <%s> is already in a group!",
  player_group_conflict_you  = "#! You are already in an XM group!",
  player_offline_they        = "#! <%s> is offline!",
  player_no_group_they       = "#! <%s> is not in an XM group!",

  invite_usage           = "#! Usage: /xm_invite <player>",
  invite_rate_limit_you  = "#! You are sending invites too often!",
  invite_rate_limit_they = "#! <%s> already has a pending invite!",
  invite_notify_group    = "#! %s invited %s to join the XM group!",
  invite_notify_they     = "#! %s has invited you to join their XM group! To accept: /xm-join",

  join_no_invites_you = "#! You have no valid invite!",
  join_group_missing  = "#! Invalid invite, group doesn't exist!",
  join_notify_group   = "#! %s has joined the XM Group!",

  leave_notify_group = "#! <%s> has quit the XM Group!",

    -- group related, non-specific
  group_new      = "#! Created New XM Group!",
  group_xm_usage = "#! Usage: /xm <message>",
  group_xm_send  = "#xm/<%s> %s",
  group_members  = "#! <%s>'s XM Group (%s / %s): %s",

    -- command descriptions
  cmd_new    = "Create a new XM group",
  cmd_invite = "Invite a player to your XM group",
  cmd_join   = "Accept a pending XM invitation",
  cmd_quit   = "Leave your XM group",
  cmd_xm     = "Send a message to your XM group",
  cmd_list   = "List members of your XM group, or another player's group",
  cmd_dump   = "Dump xm data to log",
} -- this should make translating a little easier.
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
