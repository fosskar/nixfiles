// applies the device configuration in `cfg`, which openwrt-render prepends.
// cfg.mode "plan" only reports changes; "apply" makes them and arms a
// rollback that restores every changed file unless the deploy confirms.

let uci = require('uci');
let fs = require('fs');

const plan = cfg.mode == 'plan';
const root = cfg.root ?? '';
const state = root + '/tmp/nix-uci';
const rollback_after = 120;

function redact(s) {
	for (let r in cfg.redact)
		s = replace(s, r, '***');
	return s;
}

function log(line) {
	print(redact(line), '\n');
}

function q(s) {
	return "'" + replace(s, "'", "'\\''") + "'";
}

function run(cmd) {
	let rc = system(cmd);
	if (rc != 0)
		die(sprintf('command failed (%d): %s', rc, redact(cmd)));
}

// device side effects outside the managed files; the flake check sets
// cfg.no_exec and only logs them
function act(cmd) {
	if (cfg.no_exec)
		log('$ ' + cmd);
	else
		run(cmd);
}

function succeeds(cmd) {
	return system('(' + cmd + ') >/dev/null 2>&1') == 0;
}

function mkdirp(path) {
	let cur = '';
	for (let part in split(path, '/')) {
		if (part == '')
			continue;
		cur += '/' + part;
		if (!fs.stat(cur) && !fs.mkdir(cur, 0755))
			die(sprintf('mkdir %s: %s', cur, fs.error()));
	}
}

// rename into place: readers never see a partial file, secrets are never
// briefly world-readable
function write_file(path, content, mode) {
	mkdirp(fs.dirname(path));
	let tmp = path + '.nix-uci-tmp';
	fs.unlink(tmp);
	let fh = fs.open(tmp, 'w', mode);
	if (!fh)
		die(sprintf('open %s: %s', tmp, fs.error()));
	fh.write(content);
	fh.close();
	if (!fs.chmod(tmp, mode) || !fs.rename(tmp, path))
		die(sprintf('write %s: %s', path, fs.error()));
}

// --- packages and services

function installed(names) {
	let set = {};
	if (!length(names))
		return set;
	// exits 1 when any package is missing; it prints the installed ones
	let p = fs.popen('apk info -e ' + join(' ', map(names, q)));
	for (let n in split(p.read('all'), '\n'))
		if (n != '')
			set[n] = true;
	p.close();
	return set;
}

let have_pkgs = installed([ ...cfg.remove_packages, ...cfg.packages ]);
let remove = filter(cfg.remove_packages, p => have_pkgs[p]);
let add = filter(cfg.packages, p => !have_pkgs[p]);
for (let p in remove)
	log('- package ' + p);
for (let p in add)
	log('+ package ' + p);
if (!plan && length(remove))
	act('apk del -q ' + join(' ', map(remove, q)));
// before uci, so package default configs cannot overwrite ours
if (!plan && length(add))
	act('apk update -q && apk add -q ' + join(' ', map(add, q)));

for (let p in cfg.external_packages) {
	if (succeeds(p.check))
		continue;
	log('+ external package ' + p.name);
	if (!plan)
		act(p.install);
}

for (let s in cfg.disable_services) {
	let init = '/etc/init.d/' + s;
	if (!fs.stat(init) || !succeeds(q(init) + ' enabled'))
		continue;
	log('- service ' + s);
	if (plan)
		continue;
	act(q(init) + ' disable && ' + q(init) + ' stop');
	if (s == 'firewall')
		act('nft flush ruleset');
}

if (!plan) {
	for (let d in fs.lsdir(state) ?? []) {
		if (fs.stat(state + '/' + d + '/pending'))
			die(sprintf('unconfirmed apply in %s/%s, wait for its rollback\n', state, d));
		if (fs.stat(state + '/' + d + '/confirmed') || fs.stat(state + '/' + d + '/rolled-back'))
			run('rm -rf ' + q(state + '/' + d));
	}
}

// --- uci: staged in a copy of /etc/config, which also keeps pending luci
// changes in /tmp/.uci out of our commits

const confdir = root + '/etc/config';
const stage = state + '/stage';
run(sprintf('rm -rf %s %s && mkdir -p %s %s && cp -a %s/. %s',
	q(stage), q(state + '/delta'), q(stage), q(state + '/delta'), q(confdir), q(stage)));

let c = uci.cursor(stage, state + '/delta');
let touched = {};

function check(ok, what) {
	if (!ok)
		die(sprintf('uci %s: %s', what, c.error()));
}

function norm(v) {
	if (type(v) == 'array')
		return map(v, norm);
	if (type(v) == 'bool')
		return v ? '1' : '0';
	return '' + v;
}

// uci cannot store these, setting one deletes the option
function blank(v) {
	return v == null || v == '' || (type(v) == 'array' && !length(v));
}

// redacts before quoting, which would otherwise split a secret containing '
function show(v) {
	return type(v) == 'array' ? join(' ', map(v, x => q(redact(x)))) : q(redact(v));
}

function options(s) {
	let o = {};
	for (let k, v in s)
		if (substr(k, 0, 1) != '.')
			o[k] = v;
	return o;
}

function sync_options(conf, sid, label, want, created) {
	let have = created ? {} : options(c.get_all(conf, sid));
	for (let o, v in have) {
		if (!blank(want[o]))
			continue;
		check(c.delete(conf, sid, o), 'delete ' + label + '.' + o);
		log(sprintf('- %s.%s=%s', label, o, show(v)));
		touched[conf] = true;
	}
	for (let o, v in want) {
		if (o == '_type' || blank(v))
			continue;
		let nv = norm(v);
		if (sprintf('%J', have[o]) == sprintf('%J', nv))
			continue;
		check(c.set(conf, sid, o, nv), 'set ' + label + '.' + o);
		if (have[o] == null)
			log(sprintf('+ %s.%s=%s', label, o, show(nv)));
		else
			log(sprintf('~ %s.%s=%s (was %s)', label, o, show(nv), show(have[o])));
		touched[conf] = true;
	}
}

function sync_named(conf, name, want) {
	let label = conf + '.' + name;
	if (type(want) != 'object' || !want._type)
		die(label + ' has no _type');
	let t = c.get(conf, name);
	if (t != null && t != want._type) {
		check(c.delete(conf, name), 'delete ' + label);
		log(sprintf('- %s (%s)', label, t));
		t = null;
	}
	if (t == null) {
		check(c.set(conf, name, want._type), 'set ' + label);
		log(sprintf('+ %s (%s)', label, want._type));
		touched[conf] = true;
	}
	sync_options(conf, name, label, want, t == null);
}

// replaces all anonymous sections of type t; named sections of that type stay
function sync_list(conf, t, want) {
	let old = [];
	c.foreach(conf, t, s => {
		if (s['.anonymous'])
			push(old, s['.name']);
	});
	for (let i, w in want) {
		let label = sprintf('%s.@%s[%d]', conf, t, i);
		if (w._type != t)
			die(sprintf('%s: _type %s must equal the list name', label, w._type));
		if (i < length(old)) {
			sync_options(conf, old[i], label, w, false);
			continue;
		}
		let sid = c.add(conf, t);
		check(sid, 'add ' + label);
		log(sprintf('+ %s (%s)', label, t));
		touched[conf] = true;
		sync_options(conf, sid, label, w, true);
	}
	for (let i = length(want); i < length(old); i++) {
		check(c.delete(conf, old[i]), 'delete ' + conf + '.' + old[i]);
		log(sprintf('- %s.@%s[%d]', conf, t, i));
		touched[conf] = true;
	}
}

for (let conf in keys(cfg.uci.settings))
	if (!fs.stat(stage + '/' + conf))
		fs.writefile(stage + '/' + conf, '');
for (let conf in fs.lsdir(stage))
	c.load(conf);

for (let path in cfg.uci.delete) {
	let p = split(path, '.');
	if (length(p) < 2 || length(p) > 3)
		die('uci.delete: expected config.section[.option], got ' + path);
	if (c.get(...p) == null)
		continue;
	check(c.delete(...p), 'delete ' + path);
	log('- ' + path);
	touched[p[0]] = true;
}

for (let conf, sections in cfg.uci.settings)
	for (let name, sec in sections)
		if (type(sec) == 'array')
			sync_list(conf, name, sec);
		else
			sync_named(conf, name, sec);

for (let conf in cfg.uci.exclusive) {
	let want = cfg.uci.settings[conf];
	let drop = [];
	c.foreach(conf, null, s => {
		let keep = s['.anonymous'] ? type(want[s['.type']]) == 'array' : type(want[s['.name']]) == 'object';
		if (!keep)
			push(drop, s);
	});
	for (let s in drop) {
		check(c.delete(conf, s['.name']), 'delete ' + conf + '.' + s['.name']);
		log(sprintf('- %s.%s (%s)', conf, s['.anonymous'] ? '@' + s['.type'] : s['.name'], s['.type']));
		touched[conf] = true;
	}
}

// --- everything below writes whole files: changed uci configs, managed
// files, /etc/shadow

let writes = [];
let reload = [];
let restart = {};

function stat_mode(path) {
	let st = fs.stat(path);
	return st ? st.mode : null;
}

for (let conf in sort(keys(touched))) {
	check(c.commit(conf), 'commit ' + conf);
	let path = confdir + '/' + conf;
	let old = fs.readfile(path);
	let next = fs.readfile(stage + '/' + conf);
	if (old == next)
		continue;
	push(writes, { path, content: next, mode: stat_mode(path) ?? 0644, old, old_mode: stat_mode(path) });
	push(reload, conf);
}

for (let f in cfg.files) {
	let path = root + f.path;
	let old_mode = stat_mode(path);
	let old = old_mode != null ? fs.readfile(path) : null;
	if (old == f.content && old_mode == f.mode)
		continue;
	if (old == null)
		log('+ file ' + f.path);
	else if (old != f.content)
		log('~ file ' + f.path);
	else
		log(sprintf('~ file %s mode %04o (was %04o)', f.path, f.mode, old_mode));
	push(writes, { path, content: f.content, mode: f.mode, old, old_mode });
	for (let s in f.restart)
		restart[s] = true;
}

if (cfg.root_password_hash != null) {
	let path = root + '/etc/shadow';
	let old = fs.readfile(path);
	if (old == null)
		die('read /etc/shadow: ' + fs.error());
	let lines = split(old, '\n');
	let found = false;
	for (let i, l in lines) {
		let f = split(l, ':');
		if (f[0] != 'root')
			continue;
		found = true;
		f[1] = cfg.root_password_hash;
		lines[i] = join(':', f);
	}
	if (!found)
		die('/etc/shadow has no root entry');
	let next = join('\n', lines);
	if (next != old) {
		log('~ root password');
		push(writes, { path, content: next, mode: stat_mode(path), old, old_mode: stat_mode(path) });
	}
}

if (!length(writes)) {
	log('no changes');
	exit(0);
}

let reload_lines = [];
for (let conf in reload) {
	let init = q('/etc/init.d/' + conf);
	let event = q(sprintf('%J', { type: 'config.change', data: { package: conf } }));
	push(reload_lines, sprintf('if [ -x %s ]; then %s reload || %s restart; else ubus call service event %s; fi', init, init, init, event));
}
for (let s in sort(keys(restart)))
	push(reload_lines, sprintf('%s restart', q('/etc/init.d/' + s)));
if (length(reload))
	log('reload: ' + join(' ', reload));
if (length(restart))
	log('restart: ' + join(' ', sort(keys(restart))));

if (plan)
	exit(0);

// --- apply with rollback

let dir = state + '/' + trim(fs.readfile('/proc/sys/kernel/random/uuid'));
mkdirp(dir + '/snapshot');
let restore = [];
for (let i, w in writes) {
	if (w.old == null) {
		push(restore, 'rm -f ' + q(w.path));
		continue;
	}
	let snap = dir + '/snapshot/' + i;
	write_file(snap, w.old, w.old_mode);
	push(restore, sprintf('cp -p %s %s && mv %s %s', q(snap), q(w.path + '.nix-uci-tmp'), q(w.path + '.nix-uci-tmp'), q(w.path)));
}
fs.writefile(dir + '/pending', '');
fs.writefile(dir + '/watchdog.sh', join('\n', [
	'sleep ' + rollback_after,
	// mv is atomic, so either the deploy confirms or this rolls back
	sprintf('mv %s %s || exit 0', q(dir + '/pending'), q(dir + '/rolled-back')),
	...restore,
	...reload_lines,
	'',
]));
fs.writefile(dir + '/apply.sh', join('\n', [
	...reload_lines,
	'touch ' + q(dir + '/reloaded'),
	'',
]));
act(sprintf('setsid sh %s >%s 2>&1 </dev/null &', q(dir + '/watchdog.sh'), q(dir + '/watchdog.log')));

for (let w in writes)
	write_file(w.path, w.content, w.mode);

// detached: a network reload can kill this ssh session
act(sprintf('setsid sh %s >%s 2>&1 </dev/null &', q(dir + '/apply.sh'), q(dir + '/apply.log')));
log('nix-uci-pending: ' + dir);
