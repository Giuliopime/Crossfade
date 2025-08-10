<p align="center">
   <a href="https://crossfade.giuliopime.dev">
      <img src="https://raw.githubusercontent.com/Giuliopime/Crossfade/main/website/assets/logos/logo_liquid.png" alt="Crossfade" width="124">
   </a>
<h1 align="center">Crossfade</h1>
<p>

<p align="center">
<a href="https://apps.apple.com/us/app/crossfade-convert-music-link/id6749610876">
      <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"
      alt="Get it on App Store"
      height="40">
   </a>
</p>


## Contributing
This is a plain iOS app, nothing special about it so you should be able to simply open the project with Xcode and get rollin'.
### things to improve
- [ ] localization
- [ ] add more platforms
- [ ] iPad support
- [ ] mac support

### ideas
- [ ] adding support for albums and artists, currently the app only supports track links
- [ ] add track information to the track analysis view using on device AI (like track the story behind the track)

### external APIs used
you can create your own oauth client on the following platforms for self-hosting or doing stuff differently
- Apple Music via MusicKit (no configuration required)
- Spotify API: [Dashboard](https://developer.spotify.com/dashboard)
- SoundCloud API: [Dashboard](https://soundcloud.com/you/apps)
- YouTube API: [Dashboard](https://console.cloud.google.com/apis/credentials)

### Website
The website is made purely with html, css.  
Feel free to unleash your creativity :)

#### Styling
It uses tailwind for easier styling, through the Standalone Tailwind CLI --> https://tailwindcss.com/blog/standalone-cli.  

Follow the instructions to install the cli and make sure you add it to your path.  
This repository has a git precommit hook that runs the css generation command for tailwind, which takes the `website/input.css` file and generates the minimized css at `website/output.css`.  

#### Dev environment
Setup the git precommit hook using the setup command in the `website` folder:
```bash
./website/setup.sh
```

Also make sure to run the tailwind cli while editing the website to see the right styling:
```shell
tailwindcss -i website/input.css -o website/output.css --watch
```
*Useful infos about the standalone cli on this thread: https://github.com/tailwindlabs/tailwindcss/discussions/15855#discussion-7869567*