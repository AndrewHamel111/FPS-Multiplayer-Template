This repo represents an effort to improve the Multiplayer Template which I learned Godot Multiplayer in order to mirror some of the improvements I expect any other ordinary user would need to make. These changes will include basic usability improvements as well as expanding the capabilities of the template with crucial refactors. I've been working on a project which started with this template, and I have had to make many of these changes in my own project, so I felt it was only fair to make these kinds of improvements public. Below is a basic outline of what sorts of changes are planned. More to come.

- [ ] Save User Preferences (sensitivity, whether to use UPNP, other new game options to be added)
- [ ] Text Based Game Chat
- [ ] Pre-game Lobby
- [ ] Controller Improvements (aim assist / aim magnetism)
- [ ] Server-side Map Loading (host can choose map, clients independently load map)
- [ ] Player Identity
- [ ] Scoreboard
- [ ] Basic Weapon Definitions
- [ ] Server-side Game Rules (Player health, Timed vs Score gameplay, weapon exclusions)

The nature of some of these changes obviously push this template further from being as widely reusable as the original template, however some of the refactors which are included are absolutely necessary to be able to build a game with any sort of depth or feature set.

Below is the original README for the template.

<p align="center">
  <img src="https://github.com/user-attachments/assets/38561c4c-d22c-4d7d-9dc2-8fd8de6a8f66" alt="FPS multiplayer template screenshot" />
</p>

<p align="center">
An FPS multiplayer template with everything you'd need to get started. Includes a full map with custom 3d assets.
There is a fully featured main menu, pause menu and options panel. Did I also mention it has full controller support?
</p>

## Installation
  Open the godot project manager, switch to the asset library and search ``FPS multiplayer template`` and download. Another method is to clone the repo into your godot projects folder and open it from there.

## Features
- Multiplayer
- Full map with custom assets
- Controller support (including menus)
- Cinematic Main menu
- Pause menu
- Options menu with:
  - Fullscreen
  - Fps and ping counters
  - Mouse and controller sensitivity
- Bullet wall collision
- Random respawn on map
- Adjusted light and environment ("better graphics")
### New
 - Music (with toggle) and bullet sounds (thanks to [bearlikelion](https://github.com/bearlikelion))
 - Configurable random respawns Player > Inspector > Spawns
 - QOL:
    - added tooltips for exported variables
    - code refactor (thanks to [bearlikelion](https://github.com/bearlikelion) and me)
    - bug fixes

## Controls
  - C to toggle mouse capture
  - F or (sony square)/(x on xbox) to respawn
  - Left click / Right trigger to shoot
  - Esc / start for pause menu

## Multiplayer
When pressing host view the console to get an IP for your session and give that to your friends (be careful because its your public IP)

#### troubleshooting
If you get a upnp error in the console then make sure that you have UPNP enabled on your router. If the error persists you have to port forward port 9999 then share your public IP which you can get [here](https://api.ipify.org/)
 
## Assets
- The 3d assets are made by me and go by the same MIT license, so you are free to use them in your commercial games
- The textures are made by [kenny](https://kenney.itch.io/) and go by the CC0 license so if you like them please go [donate to them](https://kenney.itch.io/kenney-donation)

## Credits
- Textures used are made by [kenny](https://kenney.itch.io/) and pre-packaged for godot by [Calinou](https://godotengine.org/asset-library/asset?user=Calinou)
- The base multiplayer functionality was made by following a [tutorial](https://www.youtube.com/watch?v=n8D3vEx7NAE) from [DevLogLogan](https://www.youtube.com/@DevLogLogan)
- Menu Music: https://freesound.org/people/magmadiverrr/sounds/661248/
- Gun Shot Sound: https://freesound.org/people/DarkShroom/sounds/645317/

## Contributors
- [bearlikelion](https://github.com/bearlikelion) Great changes including audio and code refactoring
