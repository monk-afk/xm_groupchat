# XM Group Chat

Ownerless and equal permission chat groups.

[![ContentDB](https://content.luanti.org/packages/monk/xm_groupchat/shields/downloads/)](https://content.luanti.org/packages/monk/xm_groupchat/)

Provides a set of commands to manage and chat in XM group.

Uses `mod_storage` to save member data.

___

### Commands

**/xm-new**

  - Create a new XM group.
  - Any player may create groups freely.
  - Each player may only belong to one group at a time.

**/xm-invite <player_name>**

  - Invite another player to your XM group.
  - Any group member can invite others to join the group.
  - Invites are rate-limited by a 60-second expiration timer.
  - You can only invite someone not already in a group.

**/xm-join**

  - Join the group you’ve been invited to.
  - The invite is auto-declined in 60 seconds.

**/xm-quit**

  - Leave your current XM group.
  - Groups are deleted when the last member leaves the group.
  - Groups with one member are deleted when that player exits the server.

**/xm-list [player_name]**

  - List members of your own group, or of another player’s group.
  - Member names are color-coded: green for online, red for offline.

**/xm <message>**

  - Send a message to your XM group.
  - Messages are prefixed with `#xm/`.
  - Can easily be extended or filtered by other mods.

**/xm-dump**
  - Requires the server privilege.
  - Dumps all XM tables to debug.txt for inspection.

___

>> TODO:
  - [x] Save to mod storage
  - [ ] ~~Modulate into separate files~~
  - [ ] Hook into external API (filtering, chat ranks)
  - [ ] Better description of commands
  - [ ] Organize system messages

___

MIT © 2025 monk
