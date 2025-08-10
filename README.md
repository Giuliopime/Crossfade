# Crossfade - WIP


### external APIs used
- Apple Music via MusicKit (no configuration required)
- Spotify API: [Dashboard](https://developer.spotify.com/dashboard)
- SoundCloud API: [Dashboard](https://soundcloud.com/you/apps)
- YouTube API: [Dashboard](https://console.cloud.google.com/apis/credentials)

### improvements
- [ ] AI track information 

## Contributing

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