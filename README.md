# XM Group Chat

Ownerless and equal permission join-by-invite group based chat.

Provides a set of commands to self-manage and chat in XM group.

Uses `mod_storage` to save group and member data.

### Commands

**/xm_new**

  - Create a new XM group.
  - Any player may create groups freely.
  - Each player may only belong to one group at a time.

**/xm_invite <player_name>**

  - Invite another player to your XM group.
  - Invites are rate-limited by a 60-second expiration timer.
  - Any group member can invite others to join the group.
  - You can only invite players who aren’t already in a group.

**/xm_join**

  - Join the group you’ve been invited to.
  - To decline, simply ignore the invite and it will expire automatically.

**/xm_leave**

  - Leave your current XM group.
  - Groups are deleted when the last member leaves the group.
  - Groups with one member are deleted when that player exits the server.

**/xm_list [player_name]**

  - List members of your own group, or of another player’s group.
  - Member names are color-coded: green for online, red for offline.

**/xm <message>**

  - Send a message to your XM group.
  - Messages are prefixed with `#xm/`.
  - Can easily be extended or filtered by other mods.

**/xm_dump**
  - Requires the server privilege.
  - Dumps all XM tables to debug.txt for inspection.

___

>> TODO:
  - [x] Save to mod storage
  - [ ] ~~Modulate into separate files~~
  - [ ] Hook into external API (filtering, chat ranks)
  - [ ] Better description of commands
___

MIT © 2025 monk
