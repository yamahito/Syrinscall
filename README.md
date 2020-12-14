# Syrinscall
Shareable controls for syrinscape online

Syrinscall is a simple one-page website control panel, designed to allow subscribers of Syrinscape (https://www.syrinscape.com) to share control of the online players with other members of their roleplaying groups.

## Using Syrinscall

There is a live demo of syrinscall hosted on github, while traffic allows:

https://yamahito.github.io/Syrinscall/

There are a few settings that must be made before Syrinscall will *do* anything:
1. Specify your API key; you can find this at your online control panel at https://www.syrinscape.com/online/cp/
2. Add any soundsets or elements that you wish to control, using their 'pk' number.  Syrinscape will automatically load all moods and their associated elements from the given soundsets, and show them when they play.

Elements which are added from the settings pane - or which are pinned from the control panel - are always visible.

Soundsets, elements and the API key can all be provided as part of the URL for easy sharing with members of your group.  Multiple values are concatenated using a '+' character.

### Example

The following URL (API key redacted) will load the 'witchwood' soundset with the pinned music elements 'Dark Elf Harpist' and 'A Nervous Wait':

https://yamahito.github.io/Syrinscall/?sets=1&elems=3964%2B3965&auth_token=XXX_REPLACE_WITH_YOUR_AUTH_TOKEN_HERE_XXX

## Hosting your own instance of Syrinscall

Hosting the page itself is as simple as placing the contents of this repository in a web browser, but for one complication: the page must be configured to point at a CORS proxy such as CORS-Anywhere (https://github.com/Rob--W/cors-anywhere), or else the calls to Syrinscape's API will be blocked by the cross-origin security policy.

Configuring the CORS proxy can be as simple as supplying the `cors` parameter in the URL (useful for local development), by providing the parameter `CORSproxy` to the js function `SaxonJS.transform()` in the HTML (see also https://www.saxonica.com/saxon-js/documentation/index.html#!api/transform), or by editing and recompiling the `js/Syrinscall.xsl` stylesheet.

## Contributing

Please feel free to raise bugs and feature requests as issues: https://github.com/yamahito/Syrinscall/issues

Syrinscape is written using SaxonJS to implement XSLT in javascript, partly as a learning exercise.  I am neither apologising for this, nor asserting that it is the wisest choice of programming language for interacting with APIs - sometimes if all you have is a hammer, you can treat everything as a nail!  If you are familiar with XSLT, please feel free to submit a PR for any issue or feature request you care to.

Syrinscape also uses Sass, extending the bulma.io CSS framework.  Contributions to the styling of Syrinscall would be very welcome indeed.

## One more thing...

If you like a dark mode, there is an experimental dark mode version at https://yamahito.github.io/Syrinscall/darkly.html
