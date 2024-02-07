import { readFile } from 'resource:///com/github/Aylur/ags/utils.js';
import App from 'resource:///com/github/Aylur/ags/app.js';
const pkgjson = JSON.parse(readFile(App.configDir + '/package.json'));
import GLib from 'gi://GLib';
const SKIP_CHECK = true; // Directly set the check to true in the script

const v = {
    ags: `v${pkg.version}`,
    expected: `v${pkgjson.version}`,
    check: !SKIP_CHECK, // Use the SKIP_CHECK variable to control the check
};

function mismatch() {
    print(`my config expects ${v.expected}, but your ags is ${v.ags}`);
    print(`to skip the check run "AGS_SKIP_V_CHECK=true ags"`);

    App.connect('config-parsed', app => app.Quit());
    return {};
}

export default v.ags === v.expected || !v.check
    ? (await import('./js/main.js')).default
    : mismatch();
