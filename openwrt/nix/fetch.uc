// prints, as json in the uci.settings format, every section that differs
// from the factory defaults in /rom/etc/config. ARGV limits the configs.
'use strict';

let uci = require('uci');

let live = uci.cursor('/etc/config', '/tmp/nix-uci/fetch-delta');
let rom = uci.cursor('/rom/etc/config', '/tmp/nix-uci/fetch-delta');

// json with sorted keys, so option order does not count as a difference
function canon(v) {
	if (type(v) == 'object')
		return '{' + join(',', map(sort(keys(v)), k => sprintf('%J:%s', k, canon(v[k])))) + '}';
	if (type(v) == 'array')
		return '[' + join(',', map(v, canon)) + ']';
	return sprintf('%J', v);
}

function sections(c, conf) {
	let named = {}, anon = {};
	let all = c.get_all(conf);
	if (!all)
		return { named, anon };
	for (let s in sort(values(all), (a, b) => a['.index'] - b['.index'])) {
		let o = { _type: s['.type'] };
		for (let k, v in s)
			if (substr(k, 0, 1) != '.')
				o[k] = v;
		if (!s['.anonymous'])
			named[s['.name']] = o;
		else if (anon[s['.type']])
			push(anon[s['.type']], o);
		else
			anon[s['.type']] = [ o ];
	}
	return { named, anon };
}

let settings = {};
let del = [];
for (let conf in length(ARGV) ? ARGV : sort(live.configs())) {
	let l = sections(live, conf);
	let r = sections(rom, conf);
	let out = {};
	for (let n, s in l.named)
		if (canon(s) != canon(r.named[n]))
			out[n] = s;
	for (let t, s in l.anon) {
		if (canon(s) == canon(r.anon[t]))
			continue;
		if (out[t])
			die(sprintf('%s: named section %s collides with section type %s', conf, t, t));
		out[t] = s;
	}
	for (let t in keys(r.anon))
		if (!l.anon[t])
			out[t] = [];
	for (let n in keys(r.named))
		if (!l.named[n])
			push(del, conf + '.' + n);
	if (length(out))
		settings[conf] = out;
}

print(sprintf('%J\n', { settings, delete: del }));
