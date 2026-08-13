// Mocked responses for next/font/google, used at build time because the
// Nix sandbox has no network. next/font replaces real font fetching with
// these placeholder entries; the browser falls back to system fonts.
// Keys must match the exact Google Fonts CSS URLs next/font requests.

const css = (family) => `
/* mocked font: ${family} */
@font-face {
  font-family: '${family}';
  font-style: normal;
  font-weight: 100 900;
  font-display: swap;
  src: url(https://fonts.gstatic.com/s/mock/${family.toLowerCase().replace(/ /g, "-")}.woff2) format('woff2');
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;
}
`;

module.exports = {
  "https://fonts.googleapis.com/css2?family=Inter:wght@100..900&display=swap":
    css("Inter"),
  "https://fonts.googleapis.com/css2?family=Newsreader:ital,wght@0,200..800;1,200..800&display=swap":
    css("Newsreader"),
  "https://fonts.googleapis.com/css2?family=Literata:ital,wght@0,200..900;1,200..900&display=swap":
    css("Literata"),
  "https://fonts.googleapis.com/css2?family=Alegreya+Sans:ital,wght@0,400;0,500;0,700;0,800;1,400;1,500;1,700;1,800&display=swap":
    css("Alegreya Sans"),
};
