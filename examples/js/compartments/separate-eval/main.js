globalThis.x = 0;
globalThis.increment = function() {
	return (1,eval)("x++");
}
globalThis.test = function() {
    trace("app " + increment() + "\n");
}
const modules = {
	mod: new StaticModuleRecord({ archive:"mod" }),
};
let compartment = new Compartment({}, {}, {
	resolveHook(specifier, refererSpecifier) {
		return specifier;
	},
	loadNowHook(specifier) {
		return modules[specifier];
	}
});
compartment.importNow("mod");
test();
compartment.globalThis.test();
test();
compartment.globalThis.test();
